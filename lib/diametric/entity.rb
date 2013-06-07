require "bigdecimal"
require "edn"
require 'active_support/core_ext'
require 'active_support/inflector'
require 'active_model'
require 'set'
require 'value_enums'

module Diametric

  # +Diametric::Entity+ is a module that, when included in a class,
  # gives it the ability to generate Datomic schemas, queries, and
  # transactions, and makes it +ActiveModel+ compliant.
  #
  # While this allows you to use this anywhere you would use an
  # +ActiveRecord::Base+ model or another +ActiveModel+-compliant
  # instance, it _does not_ include persistence. The +Entity+ module
  # is primarily made of pure functions that take their receiver (an
  # instance of the class they are included in) and return data that
  # you can use in Datomic. +Entity+ can be best thought of as a data
  # builder for Datomic.
  #
  # Of course, you can combine +Entity+ with one of the two available
  # Diametric persistence modules for a fully persistent model.
  #
  # When +Entity+ is included in a class, that class is extended with
  # {ClassMethods}.
  #
  # @!attribute dbid
  #   The database id assigned to the entity by Datomic.
  #   @return [Integer]
  module Entity
    Ref = "ref"
    # Conversions from Ruby types to Datomic types.
    VALUE_TYPES = {
      Symbol => "keyword",
      String => "string",
      Integer => "long",
      Float => "float",
      BigDecimal => "bigdec",
      DateTime => "instant",
      URI => "uri"
    }

    DEFAULT_OPTIONS = {
      :cardinality => :one
    }

    @temp_ref = -1000

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:extend, ActiveModel::Naming)
      base.send(:include, ActiveModel::Conversion)
      base.send(:include, ActiveModel::Dirty)
      base.send(:include, ActiveModel::Validations)

      base.class_eval do
        @attributes = {}
        @defaults = {}
        @enums = {}
        @namespace_prefix = nil
        @partition = :"db.part/user"
      end
    end

    def self.next_temp_ref
      @temp_ref -= 1
    end

    # @!attribute [rw] partition
    #   The Datomic partition this entity's data will be stored in.
    #   Defaults to +:db.part/user+.
    #   @return [String]
    #
    # @!attribute [r] attributes
    #   @return [Array] Definitions of each of the entity's attributes (name, type, options).
    #
    # @!attribute [r] defaults
    #   @return [Array] Default values for any entitites defined with a +:default+ key and value.
    module ClassMethods
      def partition
        @partition
      end

      def partition=(partition)
        self.partition = partition.to_sym
      end

      def attributes
        @attributes
      end

      def defaults
        @defaults
      end

      # Set the namespace prefix used for attribute names
      #
      # @param prefix [#to_s] The prefix to be used for namespacing entity attributes
      #
      # @example Override the default namespace prefix
      #   class Mouse
      #     include Diametric::Entity
      #
      #     namespace_prefix :mice
      #   end
      #
      #   Mouse.new.prefix # => :mice
      #
      # @return void
      def namespace_prefix(prefix)
        @namespace_prefix = prefix
      end

      # Add an attribute to a {Diametric::Entity}.
      #
      # Valid options are:
      #
      # * +:index+: The only valid value is +true+. This causes the
      #   attribute to be indexed for easier lookup.
      # * +:unique+: Valid values are +:value+ or +:identity.+
      #   * +:value+ causes the attribute value to be unique to the
      #     entity and attempts to insert a duplicate value will fail.
      #   * +:identity+ causes the attribute value to be unique to
      #     the entity. Attempts to insert a duplicate value with a
      #     temporary entity id will result in an "upsert," causing the
      #     temporary entity's attributes to be merged with those for
      #     the current entity in Datomic.
      # * +:cardinality+: Specifies whether an attribute associates
      #   a single value or a set of values with an entity. The
      #   values allowed are:
      #   * +:one+ - the attribute is single valued, it associates a
      #     single value with an entity.
      #   * +:many+ - the attribute is mutli valued, it associates a
      #     set of values with an entity.
      #   +:one+ is the default.
      # * +:doc+: A string used in Datomic to document the attribute.
      # * +:fulltext+: The only valid value is +true+. Indicates that a
      #   fulltext search index should be generated for the attribute.
      # * +:default+: The value the attribute will default to when the
      #   Entity is initialized. Defaults for attributes with +:cardinality+ of +:many+
      #   will be transformed into a Set by passing the default to +Set.new+.
      #
      # @example Add an indexed name attribute.
      #   attribute :name, String, :index => true
      #
      # @param name [String] The attribute's name.
      # @param value_type [Class] The attribute's type.
      #   Must exist in {Diametric::Entity::VALUE_TYPES}.
      # @param opts [Hash] Options to pass to Datomic.
      #
      # @return void
      def attribute(name, value_type, opts = {})
        opts = DEFAULT_OPTIONS.merge(opts)

        establish_defaults(name, value_type, opts)

        @attributes[name] = {:value_type => value_type}.merge(opts)

        setup_attribute_methods(name, opts[:cardinality])
      end

      # @return [Array<Symbol>] Names of the entity's attributes.
      def attribute_names
        @attributes.keys
      end

      # @return [Array<Symbol>] Names of the entity's enums.
      def enum_names
        @enums.keys
      end

      # Add an enum to a {Diametric::Entity}.
      #
      # enum is used when attribute type is Ref and refers
      # a set of values.
      # name should be the same as corresponding attribute name.
      #
      # @example Add an enum of colors
      #   class Palette
      #     attribute :color, Ref
      #     enum :color, [:blue, :green, :yellow, :orange]
      #   end
      #   p = Pallet.new
      #   p.color = Pallet::Color::Green
      #
      # @param name [Symbol] The enum's name.
      # @param values [Array] The enum values.
      #
      # @return void
      def enum(name, values)
        enum_values = nil
        enum_values = values.to_set if values.is_a?(Array)
        enum_values = values if values.is_a?(Set)
        raise RuntimeError "values should be Array or Set" if enum_values.nil?
        enum_name = name.to_s.capitalize
        syms = values.collect(&:to_s).collect(&:upcase).collect(&:to_sym)
        class_eval("module #{enum_name};enum #{syms};end")
        @enums[name] = syms
      end

      # Generates a Datomic schema for a model's attributes.
      #
      # @return [Array] A Datomic schema, as Ruby data that can be
      #   converted to EDN.
      def schema
        return peer_schema if self.instance_variable_get("@peer")
        rest_schema
      end

      def rest_schema
        defaults = {
          :"db/id" => tempid(:"db.part/db"),
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => :"db.part/db"
        }

        schema_array = @attributes.reduce([]) do |schema, (attribute, opts)|
          opts = opts.dup
          value_type = opts.delete(:value_type)

          unless opts.empty?
            opts[:cardinality] = namespace("db.cardinality", opts[:cardinality])
            opts[:unique] = namespace("db.unique", opts[:unique]) if opts[:unique]
            opts = opts.map { |k, v|
              k = namespace("db", k)
              [k, v]
            }
            opts = Hash[*opts.flatten]
          end

          schema << defaults.merge({
                                     :"db/ident" => namespace(prefix, attribute),
                                     :"db/valueType" => value_type(value_type),
                                   }).merge(opts)
        end

        enum_schema = [
          :"db/add", tempid(:"db.part/user"), :"db/ident"
        ]
        prefix = self.name.downcase
        @enums.each do |key, values|
          values.each do |value|
            ident_value = :"#{prefix}.#{key.downcase}/#{value.to_s.sub(/_/, "-").downcase}"
            es = [:"db/add", tempid(:"db.part/user"), :"db/ident", ident_value]
            schema_array << es
          end
        end
        schema_array
      end

      # Generates a Datomic schema for a model's attributes.
      #
      # @return [Array] A Datomic schema, as Ruby data that can be
      #   converted to EDN.
      def peer_schema
        defaults = {
          ":db/cardinality" => ":db.cardinality/one",
          ":db.install/_attribute" => ":db.part/db"
        }

        schema_array = @attributes.reduce([]) do |schema, (attribute, opts)|
          opts = opts.dup
          value_type = opts.delete(:value_type)

          unless opts.empty?
            opts[:cardinality] = namespace("db.cardinality", opts[:cardinality])
            opts[:unique] = namespace("db.unique", opts[:unique]) if opts[:unique]
            opts = opts.map { |k, v|
              k = namespace("db", k)
              [k, v]
            }
            opts = Hash[*opts.flatten]
          end

          schema << defaults.merge({
                                     ":db/id" => Diametric::Persistence::Peer.tempid(":db.part/db"),
                                     ":db/ident" => namespace(prefix, attribute),
                                     ":db/valueType" => value_type(value_type),
                                   }).merge(opts)
        end

        prefix = self.name.downcase
        @enums.each do |key, values|
          values.each do |value|
            ident_value = ":#{prefix}.#{key.downcase}/#{value.to_s.sub(/_/, "-").downcase}"
            es = [":db/add", Diametric::Persistence::Peer.tempid(":db.part/user"), ":db/ident", ident_value]
            schema_array << es
          end
        end
        schema_array
      end

      # Given a set of Ruby data returned from a Datomic query, this
      # can re-hydrate that data into a model instance.
      #
      # @return [Entity]
      def from_query(query_results, connection=nil, resolve=false)
        dbid = query_results.shift
        widget = self.new(Hash[attribute_names.zip query_results])
        widget.dbid = dbid

        if resolve
          widget = resolve_ref_dbid(widget, connection)
        end
        widget
      end

      def resolve_ref_dbid(parent, connection)
        parent.class.attribute_names.each do |e|
          if parent.class.attributes[e][:value_type] == "ref"
            ref = parent.instance_variable_get("@#{e.to_s}")
            if ref.is_a?(Fixnum) || ref.is_a?(Java::DatomicQuery::EntityMap)
              child = from_dbid_or_entity(ref, connection)
              child = resolve_ref_dbid(child, connection)
              parent.instance_variable_set("@#{e.to_s}", child)
            elsif ref.is_a?(Set)
              children = ref.inject(Set.new) do |memo, entity|
               child = from_dbid_or_entity(entity, connection)
                memo.add(child)
                memo
              end
              parent.instance_variable_set("@#{e.to_s}", children)
            end
          end
        end
        parent
      end

      def from_dbid_or_entity(thing, conn_or_db, resolve=false)
        return thing unless conn_or_db

        if conn_or_db.respond_to?(:db)
          conn_or_db = conn_or_db.db
        end

        if thing.is_a? Fixnum
          dbid = thing
          entity = conn_or_db.entity(dbid)
        elsif thing.respond_to?(:eid)
          dbid = thing.eid
          if entity.respond_to?(:keys)
            entity = thing
          else
            entity = conn_or_db.entity(dbid)
          end
        elsif thing.respond_to?(:to_java)
          dbid = thing.to_java
          entity = conn_or_db.entity(dbid)
        else
          return thing
        end
        first_key = entity.keys.first
        match_data = /:([a-zA-Z0-9_]+)\/([a-zA-Z0-9_]+)/.match(first_key)
        entity_name = match_data[1].capitalize
        instance = eval("#{entity_name}.new")
        instance.send("#{match_data[2]}=", entity[first_key])
        entity.keys[1..-1].each do |key|
          match_data = /:([a-zA-Z0-9]+)\/([a-zA-Z0-9_]+)/.match(key)
          instance.send("#{match_data[2]}=", entity[key])
        end
        instance.send("dbid=", Diametric::Persistence::Object.new(dbid))

        if resolve
          instance = resolve_ref_dbid(instance, conn_or_db)
        end

        instance
      end

      def find(id)
        if self.instance_variable_get("@peer")
          connection ||= Diametric::Persistence::Peer.connect
        end
        from_dbid_or_entity(id, connection)
      end

      # Returns the prefix for this model used in Datomic. Can be
      # overriden by declaring {#namespace_prefix}
      #
      # @example
      #   Mouse.prefix #=> "mouse"
      #   FireHouse.prefix #=> "fire_house"
      #   Person::User.prefix #=> "person.user"
      #
      # @return [String]
      def prefix
        @namespace_prefix || self.to_s.underscore.sub('/', '.')
      end

      # Create a temporary id placeholder.
      #
      # @param e [*#to_edn] Elements to put in the placeholder. Should
      #   be either partition or partition and a negative number to be
      #   used as a reference.
      #
      # @return [EDN::Type::Unknown] Temporary id placeholder.
      def tempid(*e)
        if self.instance_variable_get("@peer")
          if e[0].to_s.include?("user")
            return Diametric::Persistence::Peer.tempid(":db.part/user")
          else
            return Diametric::Persistence::Peer.tempid(":db.part/db")
          end
        else
          EDN.tagged_element('db/id', e)
        end
      end

      # Namespace a attribute for Datomic.
      #
      # @param ns [#to_s] Namespace.
      # @param attribute [#to_s] Attribute.
      #
      # @return [Symbol] Namespaced attribute.
      def namespace(ns, attribute)
        if self.instance_variable_get("@peer")
          ":" + [ns.to_s, attribute.to_s].join("/")
        else
          [ns.to_s, attribute.to_s].join("/").to_sym
        end
      end

      # Raise an error if validation failed.
      #
      # @example Raise the validation error.
      #   Person.fail_validate!(person)
      #
      # @param [ Entity ] entity The entity to fail.
      def fail_validate!(entity)
        raise Errors::ValidationError.new(entity)
      end

      private

      def value_type(vt)
        if vt.is_a?(Class)
          vt = VALUE_TYPES[vt]
        end
        namespace("db.type", vt)
      end

      def establish_defaults(name, value_type, opts = {})
        default = opts.delete(:default)
        @defaults[name] = default if default
      end

      def setup_attribute_methods(name, cardinality)
        define_attribute_method name

        define_method(name) do
          instance_variable_get("@#{name}")
        end

        define_method("#{name}=") do |value|
          send("#{name}_will_change!") unless value == instance_variable_get("@#{name}")
          if cardinality == :many
            value = Set.new(value)
          end
          instance_variable_set("@#{name}", value)
        end
      end
    end

    def dbid
      @dbid
    end

    def dbid=(dbid)
      @dbid = dbid
    end

    alias :id :dbid
    alias :"id=" :"dbid="

    # Create a new {Diametric::Entity}.
    #
    # @param params [Hash] A hash of attributes and values to
    #   initialize the entity with.
    def initialize(params = {})
      self.class.defaults.merge(params).each do |k, v|
        self.send("#{k}=", v)
      end
    end

    # @return [Integer] A reference unique to this entity instance
    #   used in constructing temporary ids for transactions.
    def temp_ref
      @temp_ref ||= Diametric::Entity.next_temp_ref
    end

    # Creates data for a Datomic transaction.
    #
    # @param attribute_names [*Symbol] Attribute names to save in the
    #   transaction. If no names are given, any changed
    #   attributes will be saved.
    #
    # @return [Array] Datomic transaction data.
    def tx_data(*attribute_names)
      attribute_names = self.changed_attributes.keys if attribute_names.empty?

      entity_tx = {}
      txes = []
      attribute_names.each do |attribute_name|
        cardinality = self.class.attributes[attribute_name.to_sym][:cardinality]

        #if cardinality == :many && self.class.instance_variable_get("@peer").nil?
        if cardinality == :many
          txes += cardinality_many_tx_data(attribute_name)
        else
          entity_tx[self.class.namespace(self.class.prefix, attribute_name)] = self.send(attribute_name)
        end
      end

      if entity_tx.present?
        if self.class.instance_variable_get("@peer")
          @dbid ||= tempid
          txes << entity_tx.merge({":db/id" => dbid})
        else
          txes << entity_tx.merge({:"db/id" => dbid || tempid})
        end
      end
      txes
    end

    def cardinality_many_tx_data(attribute_name)
      prev = Array(self.changed_attributes[attribute_name]).to_set
      curr = self.send(attribute_name)

      protractions = curr - prev
      retractions = prev - curr

      namespaced_attribute = self.class.namespace(self.class.prefix, attribute_name)
      txes = []
      if self.class.instance_variable_get("@peer")
        @dbid ||= tempid
        txes_data(txes, ":db/retract", namespaced_attribute, retractions) unless retractions.empty?
        txes_data(txes, ":db/add", namespaced_attribute, protractions) unless protractions.empty?
      else
        txes << [:"db/retract", (dbid || tempid), namespaced_attribute, retractions.to_a] unless retractions.empty?
        txes << [:"db/add", (dbid || tempid) , namespaced_attribute, protractions.to_a] unless protractions.empty?
      end
      txes
    end

    def txes_data(txes, op, namespaced_attribute, set)
      set.to_a.each do |s|
        value = s.respond_to?(:dbid) ? s.dbid : s
        txes << [op, @dbid, namespaced_attribute, value]
      end
    end

    # Returns hash of all attributes for this object
    #
    # @return [Hash<Symbol, object>] Hash of atrributes
    def attributes
      Hash[self.class.attribute_names.map {|attribute_name| [attribute_name, self.send(attribute_name)] }]
    end

    # @return [Array<Symbol>] Names of the entity's attributes.
    def attribute_names
      self.class.attribute_names
    end

    # @return [EDN::Type::Unknown] A temporary id placeholder for
    #   use in transactions.
    def tempid
      self.class.tempid(self.class.partition, temp_ref)
    end

    # Checks to see if the two objects are the same entity in Datomic.
    #
    # @return [Boolean]
    def ==(other)
      return false if self.dbid.nil?
      return false unless other.respond_to?(:dbid)
      return false unless self.dbid == other.dbid
      true
    end

    # Checks to see if the two objects are of the same type, are the same
    # entity, and have the same attribute values.
    #
    # @return [Boolean]
    def eql?(other)
      return false unless self == other
      return false unless self.class == other.class

      attribute_names.each do |attr|
        return false unless self.send(attr) == other.send(attr)
      end

      true
    end

    # Methods for ActiveModel compliance.

    # For ActiveModel compliance.
    # @return [self]
    def to_model
      self
    end

    # Key for use in REST URL's, etc.
    # @return [Integer, nil]
    def to_key
      persisted? ? [dbid] : nil
    end

    # @return [Boolean] Is the entity persisted?
    def persisted?
      !dbid.nil?
    end

    # @return [Boolean] Is this a new entity (that is, not persisted)?
    def new_record?
      !persisted?
    end

    # @return [false] Is this entity destroyed? (Always false.) For
    #   ActiveModel compliance.
    def destroyed?
      false
    end

    # @return [Boolean] Is this entity valid? By default, this is
    #   always true.
    def valid?
      errors.empty?
    end

    # @return [ActiveModel::Errors] Errors on this entity. By default,
    #   this is empty.
    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    # Update method updates attribute values and saves new values in datomic.
    # The method receives hash as an argument.
    def update(attrs)
      attrs.each do |k, v|
        self.send(k.to_s+"=", v)
        self.changed_attributes[k]=v
      end
      self.save if self.respond_to? :save
      true
    end

    def destroy
      self.retract_entity(dbid)
    end
  end
end
