require "bigdecimal"
require "edn"
require 'active_support/core_ext'
require 'active_support/inflector'
require 'active_model'
require 'set'
require 'value_enums'
require 'boolean_type'

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
    UUID = "uuid"
    Double = "double"
    # Conversions from Ruby types to Datomic types.
    VALUE_TYPES = {
      Symbol => "keyword",
      String => "string",
      Integer => "long",
      Float => "double",
      BigDecimal => "bigdec",
      DateTime => "instant",
      Boolean => "boolean",
      URI => "uri",
      UUID => "uuid"
    }

    DEFAULT_OPTIONS = {
      :cardinality => :one
    }

    @temp_ref = -1000000

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
        defaults = {
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
                                     :"db/id" => tempid(:"db.part/db")
                                   }).merge(opts)
        end
        enum_schema = [
          :"db/add", tempid(:"db.part/user"), :"db/ident"
        ]
        prefix = self.to_s.underscore
        @enums.each do |key, values|
          values.each do |value|
            ident_value = :"#{prefix}.#{key.downcase}/#{value.to_s.sub(/_/, "-").downcase}"
            es = [:"db/add", tempid(:"db.part/user"), :"db/ident", ident_value]
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
            if ref.is_a?(Fixnum) ||
              (self.instance_variable_get("@peer") && ref.is_a?(Diametric::Persistence::Entity))
              child = reify(ref, connection)
              child = resolve_ref_dbid(child, connection)
              parent.instance_variable_set("@#{e.to_s}", child)
            elsif ref.is_a?(Diametric::Associations::Collection)
              children = Diametric::Associations::Collection.new(parent, e.to_s)
              ref.each do |entity|
                children.add_reified_entities(reify(entity, connection))
              end
              parent.instance_variable_set("@#{e.to_s}", children)
            elsif ref.is_a?(Set)
              children = ref.inject(Set.new) do |memo, entity|
                child = reify(entity, connection)
                memo.add(child)
                memo
              end
              parent.instance_variable_set("@#{e.to_s}", children)
            end
          end
        end
        parent
      end

      def reify(thing, conn_or_db=nil, resolve=false)
        return peer_reify(thing, conn_or_db, resolve) if self.instance_variable_get("@peer")
        rest_reify(thing, resolve)
      end

      def rest_reify(dbid, resolve)
        query = [
          :find, ~"?ident", ~"?v",
          :in, ~"\$", [~"?e"],
          :where, [~"?e", ~"?a", ~"?v"], [~"?a", :"db/ident", ~"?ident"]
        ]
        entities = self.q(query, [[dbid]])
        class_name = to_classname(entities.first.first)
        instance = eval("#{class_name}.new")
        entities.each do |k, v|
          matched_data = /([a-zA-Z0-9_\.]+)\/([a-zA-Z0-9_]+)/.match(k.to_s)
          attribute = instance.send(matched_data[2])
          if attribute && attribute.is_a?(Diametric::Associations::Collection)
            attribute.add_reified_entities(v)
          else
            instance.send("clean_#{matched_data[2]}=", v)
          end
        end
        instance.send("dbid=", dbid)

        if resolve
          instance = resolve_ref_dbid(instance, nil)
        end

        instance
      end

      def peer_reify(thing, conn_or_db=nil, resolve=false)
        conn_or_db ||= Diametric::Persistence::Peer.connect.db

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
        elsif thing.kind_of? java.lang.Long
          entity = conn_or_db.entity(Diametric::Persistence::Object.new(thing))
        elsif thing.respond_to?(:to_java)
          dbid = thing.to_java
          entity = conn_or_db.entity(dbid)
        else
          return thing
        end
        first_key = entity.keys.first
        class_name = to_classname(first_key)
        instance = eval("#{class_name}.new")
        entity.keys.each do |key|
          matched_data = /:([a-zA-Z0-9_\.]+)\/([a-zA-Z0-9_]+)/.match(key)
          instance.send("clean_#{matched_data[2]}=", entity[key])
        end
        instance.send("dbid=", Diametric::Persistence::Object.new(entity.get("db/id")))

        if resolve
          instance = resolve_ref_dbid(instance, conn_or_db)
        end

        instance
      end

      def to_classname(key)
        names = []
        # drops the first character ":"
        key = key.to_s
        if key[0] == ":"
          key = key[1..-1]
        end
        key.chars.inject("") do |memo, c|
          if c == "/"
            # means the end of class name
            names << memo
            break
          elsif c == "."
            # namespace delimiter
            names << memo
            memo = ""
          elsif c == "-"
            # Clojure uses - for name, but Ruby can't
            # converts dash to underscore
            memo << "_"
          else
            memo << c
          end
          memo
        end
        names.collect(&:camelize).join("::")
      end

      def find(id)
        if self.instance_variable_get("@peer")
          connection ||= Diametric::Persistence::Peer.connect
        end
        reify(id, connection)
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
          Diametric::Persistence::Peer.tempid(*e)
        else
          Diametric::Persistence::REST.tempid(*e)
        end
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
        @namespace_prefix || self.to_s.underscore.gsub('/', '.')
      end

      # Namespace a attribute for Datomic.
      #
      # @param ns [#to_s] Namespace.
      # @param attribute [#to_s] Attribute.
      #
      # @return [Symbol] Namespaced attribute.
      def namespace(ns, attribute)
        [ns.to_s, attribute.to_s].join("/").to_sym
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
        if vt.is_a?(Class) || vt.is_a?(Module)
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
          ivar = instance_variable_get("@#{name}")
          if ivar.nil? &&
              self.class.attributes[name][:value_type] == Ref &&
              self.class.attributes[name][:cardinality] == :many
            ivar = Diametric::Associations::Collection.new(self, name)
          end
          ivar
        end

        define_method("#{name}=") do |value|
          send("#{name}_will_change!") unless value == instance_variable_get("@#{name}")
          case self.class.attributes[name][:value_type]
          when Ref
            case cardinality
            when :many
              if value.is_a?(Enumerable) && value.first.respond_to?(:save)
                # entity type
                ivar = send("#{name}")
                instance_variable_set("@#{name}", ivar.replace(value))
              elsif value.is_a?(Diametric::Associations::Collection)
                instance_variable_set("@#{name}", value)
              elsif value.is_a?(Enumerable)
                # enum type
                # however, falls here when empty array is given for entity type
                instance_variable_set("@#{name}", Set.new(value))
              end
            when :one
              if value.respond_to?(:save)
                # entity type
                if value.save
                  instance_variable_set("@#{name}", value.dbid)
                end
              else
                # enum type
                instance_variable_set("@#{name}", value)
              end
            end
          else   # not Ref
            case cardinality
            when :many
              instance_variable_set("@#{name}", Set.new(value))
            when :one
              instance_variable_set("@#{name}", value)
            end
          end
        end

        define_method("clean_#{name}=") do |value|
          if self.class.attributes[name][:value_type] != Ref && cardinality == :many
            if value.is_a? Enumerable
              value = Set.new(value)
            else
              # used from rest reify
              ivar = instance_variable_get("@#{name}")
              ivar ||= Set.new
              value = ivar.add(value)
            end
          end
          if self.class.attributes[name][:value_type] == Ref &&
              cardinality == :many &&
              !(value.is_a? Diametric::Associations::Collection)
            if value.is_a? Enumerable
              value = Diametric::Associations::Collection.new(self, name, value)
            else
              value = Diametric::Associations::Collection.new(self, name, [value])
            end
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

        if cardinality == :many
          txes += cardinality_many_tx_data(attribute_name)
        else
          entity_tx[self.class.namespace(self.class.prefix, attribute_name)] = self.send(attribute_name)
        end
      end

      if entity_tx.present?
        @dbid ||= tempid
        txes << entity_tx.merge({:"db/id" => dbid})
      end
      txes
    end

    def cardinality_many_tx_data(attribute_name)
      changed = self.changed_attributes[attribute_name]
      prev =
        changed.is_a?(Diametric::Associations::Collection) ? changed.to_set : Array(changed).to_set
      curr = self.send(attribute_name)
      curr = curr.is_a?(Diametric::Associations::Collection) ? curr.to_set : curr

      protractions = curr - prev
      retractions = prev - curr

      namespaced_attribute = self.class.namespace(self.class.prefix, attribute_name)
      txes = []
      @dbid ||= tempid
      txes << [:"db/retract", dbid, namespaced_attribute, retractions.to_a] unless retractions.empty?
      txes << [:"db/add", dbid , namespaced_attribute, protractions.to_a] unless protractions.empty?
      txes
    end

=begin
    def txes_data(txes, op, namespaced_attribute, set)
      set.to_a.each do |s|
        value = s.respond_to?(:dbid) ? s.dbid : s
        txes << [op, @dbid, namespaced_attribute, value]
      end
    end
=end

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
