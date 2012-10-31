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
  # {ClassMethods} and has {InstanceMethods} included.
  module Entity

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
      base.send(:include, InstanceMethods)
      base.send(:extend, ActiveModel::Naming)
      base.send(:include, ActiveModel::Conversion)

      base.class_eval do
        @attributes = []
        @partition = :"db.part/db"
      end
    end

    def self.next_temp_ref
      @temp_ref -= 1
    end

    module ClassMethods
      def partition
        @partition
      end

      def partition=(partition)
        self.partition = partition.to_sym
      end

      # Add an attribute to a {Diametric::Entity}.
      #
      # Valid options are:
      #
      # * +:index+: The only valid value is +true+. This causes the
      #   attribute to be indexed for easier lookup.
      # * +:unique+: Valid values are +:value+ or +:identity.
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
      def attribute(name, value_type, opts = {})
        @attributes << [name, value_type, opts]
        attr_accessor name
      end

      # @return [Array] Definitions of each of the entity's attributes (name, type, options).
      def attributes
        @attributes
      end

      # @return [Array<Symbol>] Names of the entity's attributes.
      def attribute_names
        @attributes.map { |name, _, _| name }
      end

      def schema
        defaults = {
          :"db/id" => tempid(@partition),
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => @partition
        }

        @attributes.reduce([]) do |schema, (attribute, value_type, opts)|
          opts = opts.dup
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

      def from_query(query_results)
        dbid = query_results.shift
        widget = self.new(Hash[*(@attributes.map { |attribute, _, _| attribute }.zip(query_results).flatten)])
        widget.dbid = dbid
        widget
      end

      def prefix
        self.to_s.underscore.sub('/', '.')
      end

      def tempid(*e)
        EDN.tagged_element('db/id', e)
      end

      def namespace(ns, val)
        [ns.to_s, val.to_s].join("/").to_sym
      end

      def value_type(vt)
        if vt.is_a?(Class)
          vt = VALUE_TYPES[vt]
        end
        namespace("db.type", vt)
      end
    end

    module InstanceMethods
      def initialize(params = {})
        params.each do |k, v|
          self.send("#{k}=", v)
        end
      end

      def temp_ref
        @temp_ref ||= Diametric::Entity.next_temp_ref
      end

      def tx_data(*attributes)
        tx = {:"db/id" => dbid || tempid}
        attributes = self.attribute_names if attributes.empty?
        attributes.reduce(tx) do |t, attribute|
          t[self.class.namespace(self.class.prefix, attribute)] = self.send(attribute)
          t
        end
        [tx]
      end

      def attribute_names
        self.class.attributes.map { |attribute, _, _| attribute }
      end

      def dbid
        @dbid
      end

      def dbid=(dbid)
        @dbid = dbid
      end

      alias :id :dbid

      def tempid
        self.class.send(:tempid, self.class.partition, temp_ref)
      end

      # methods for ActiveModel compliance

      def to_model
        self
      end

      def to_key
        persisted? ? [dbid] : nil
      end

      def persisted?
        !dbid.nil?
      end

      def valid?
        true
      end

      def new_record?
        !persisted?
      end

      def destroyed?
        false
      end

      def errors
        @errors ||= ActiveModel::Errors.new(self)
      end
    end
  end
end
