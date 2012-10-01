require "diametric/version"
require "bigdecimal"
require "edn"
require 'active_support/inflector'

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

    def attr(name, value_type, opts = {})
      @attrs << [name, value_type, opts]
    end

    def attrs
      @attrs
    end

    def schema
      defaults = {
        :"db/id" => tempid(@partition),
        :"db/cardinality" => :"db.cardinality/one",
        :"db.install/_attribute" => @partition
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

    def query_data(params = {})
      vars = @attrs.map { |attr, _, _| ~"?#{attr}" }
      clauses = @attrs.map { |attr, _, _|
        [~"?e", namespace(prefix, attr), ~"?#{attr}"]
      }
      from = params.map { |k, _| ~"?#{k}" }
      args = params.map { |_, v| v }

      query = [
        :find, ~"?e", *vars,
        :from, ~"\$", *from,
        :where, *clauses
      ]

      options = {}
      options[:args] = args unless args.empty?

      [query, options]
    end

    def from_query(query_results)
      dbid = query_results.shift
      widget = self.new(Hash[*(@attrs.map { |attr, _, _| attr }.zip(query_results).flatten)])
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
        vt = Diametric::VALUE_TYPES[vt]
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

    def tx_data(*attrs)
      tx = {:"db/id" => dbid || tempid}
      attrs = self.attr_names if attrs.empty?
      attrs.reduce(tx) do |t, attr|
        t[self.class.namespace(self.class.prefix, attr)] = self.send(attr)
        t
      end
      [tx]
    end

    def attr_names
      self.class.attrs.map { |attr, _, _| attr }
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

    def method_missing(method, *params)
      if attr_names.include?(method)
        instance_variable_get("@#{method}")
      elsif method.to_s.end_with?('=') && attr_names.include?(method.to_s.chop.to_sym)
        if params.length == 1
          instance_variable_set("@#{method.to_s.chop}", params.first)
        else
          raise "Wrong number of arguments to #{method}: #{params.length} given, 1 expected."
        end
      else
        super
      end
    end
  end
end
