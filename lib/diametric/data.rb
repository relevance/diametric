require "bigdecimal"
require "edn"
require 'active_support/inflector'

module Diametric
  module Data
    VALUE_TYPES = {
      Symbol => "keyword",
      String => "string",
      Integer => "long",
      Float => "float",
      BigDecimal => "bigdec",
      DateTime => "instant",
      URI => "uri"
    }

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)

      # TODO set up :db/id
      base.class_eval do
        @attributes = []
        @partition = :"db.part/db"
      end
    end

    module ClassMethods
      def partition
        @partition
      end

      def partition=(partition)
        self.partition = partition.to_sym
      end

      def attribute(name, value_type, opts = {})
        @attributes << [name, value_type, opts]
        attr_accessor name
      end

      def attributes
        @attributes
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

      def query_data(params = {})
        vars = @attributes.map { |attribute, _, _| ~"?#{attribute}" }
        clauses = @attributes.map { |attribute, _, _|
          [~"?e", namespace(prefix, attribute), ~"?#{attribute}"]
        }
        from = params.map { |k, _| ~"?#{k}" }
        args = params.map { |_, v| v }

        query = [
          :find, ~"?e", *vars,
          :in, ~"\$", *from,
          :where, *clauses
        ]

        [query, args]
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

      def tempid
        self.class.send(:tempid, self.class.partition)
      end
    end
  end
end
