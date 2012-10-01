require "diametric/version"
require "bigdecimal"

module Diametric
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
      @attrs = []
      @part = :"db.part/db"
    end
  end

  module ClassMethods
    def tempid(part)
    end

    def namespace(ns, val)
      [ns.to_s, val.to_s].join("/").to_sym
    end

    def value_type(vt)
      if vt.is_a?(Class)
        vt = Diametric::VALUE_TYPES[vt]
      end
      namespace("db.type", vt)
    end

    def prefix
      self.to_s.downcase
    end

    def attr(name, value_type, opts = {})
      @attrs << [name, value_type, opts]
    end

    def schema
      defaults = {
        :"db/id" => tempid(@part),
        :"db/cardinality" => :"db.cardinality/one",
        :"db.install/_attribute" => @part
      }

      @attrs.reduce([]) do |schema, (attr, value_type, opts)|
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
          :"db/ident" => namespace(prefix, attr),
          :"db/valueType" => value_type(value_type),
        }).merge(opts)
      end
    end

    def query(params)
    end

    def from_query(query_results)
    end
  end

  module InstanceMethods
    def initialize(params = {})
    end

    def transact(*attrs)
    end
  end
end
