require "bigdecimal"
require "edn"
require 'active_support/core_ext'
require 'active_support/inflector'
require 'active_model'

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

    @temp_ref = -1000

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:extend, ActiveModel::Naming)
      base.send(:include, ActiveModel::Conversion)
      base.send(:include, ActiveModel::Dirty)
      base.send(:include, ActiveModel::Validations)

      base.class_eval do
        @attributes = {}
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
      #   To be honest, I have no idea how this will work in Ruby. Try +:many+ at your own risk.
      #   +:one+ is the default.
      # * +:doc+: A string used in Datomic to document the attribute.
      # * +:fulltext+: The only valid value is +true+. Indicates that a
      #   fulltext search index should be generated for the attribute.
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
        @attributes[name] = { :value_type => value_type }.merge(opts)
        define_attribute_method name
        define_method(name) do
          instance_variable_get("@#{name}")
        end
        define_method("#{name}=") do |value|
          send("#{name}_will_change!") unless value == instance_variable_get("@#{name}")
          instance_variable_set("@#{name}", value)
        end
      end

      # @return [Array<Symbol>] Names of the entity's attributes.
      def attribute_names
        @attributes.keys
      end

      # Generates a Datomic schema for a model's attributes.
      #
      # @return [Array] A Datomic schema, as Ruby data that can be
      #   converted to EDN.
      def schema
        defaults = {
          :"db/id" => tempid(:"db.part/db"),
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => :"db.part/db"
        }

        @attributes.reduce([]) do |schema, (attribute, opts)|
          opts = opts.dup
          value_type = opts.delete(:value_type)

          unless opts.empty?
            opts[:cardinality] = namespace("db.cardinality", opts[:cardinality]) if opts[:cardinality]
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
      end

      # Given a set of Ruby data returned from a Datomic query, this
      # can re-hydrate that data into a model instance.
      #
      # @return [Entity]
      def from_query(query_results)
        dbid = query_results.shift
        widget = self.new(Hash[*(attribute_names.zip(query_results).flatten)])
        widget.dbid = dbid
        widget
      end

      # Returns the prefix for this model used in Datomic.
      #
      # @example
      #   Mouse.prefix #=> "mouse"
      #   FireHouse.prefix #=> "fire_house"
      #   Person::User.prefix #=> "person.user"
      #
      # @return [String]
      def prefix
        self.to_s.underscore.sub('/', '.')
      end

      # Create a temporary id placeholder.
      #
      # @param e [*#to_edn] Elements to put in the placeholder. Should
      #   be either partition or partition and a negative number to be
      #   used as a reference.
      #
      # @return [EDN::Type::Unknown] Temporary id placeholder.
      def tempid(*e)
        EDN.tagged_element('db/id', e)
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

      private

      def value_type(vt)
        if vt.is_a?(Class)
          vt = VALUE_TYPES[vt]
        end
        namespace("db.type", vt)
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
      params.each do |k, v|
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
    # @param attributes [*Symbol] Attributes to save in the
    #   transaction. If no attributes are given, any changed
    #   attributes will be saved.
    #
    # @return [Array] Datomic transaction data.
    def tx_data(*attributes)
      tx = {:"db/id" => dbid || tempid}
      attributes = self.changed_attributes.keys if attributes.empty?
      attributes.reduce(tx) do |t, attribute|
        t[self.class.namespace(self.class.prefix, attribute)] = self.send(attribute)
        t
      end
      [tx]
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
  end
end
