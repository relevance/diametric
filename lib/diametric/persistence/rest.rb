require 'diametric'
require 'diametric/persistence/common'
require 'datomic/client'

# TODO: nice errors when unable to connect
module Diametric
  module Persistence
    module REST
      @connection = nil
      @persisted_classes = ::Set.new

      def self.included(base)
        base.send(:include, Diametric::Persistence::Common)
        base.send(:extend, ClassMethods)
        @persisted_classes.add(base)
      end

      def self.connection
        @connection
      end

      def self.create_schemas
        @persisted_classes.each do |klass|
          klass.create_schema
        end
      end

      module ClassMethods
        def connect(options = {})
          @uri = options[:uri]
          @dbalias = options[:storage]
          @database = options[:database]

          @connection = Datomic::Client.new(@uri, @dbalias)
          @connection.create_database(@database)
        end

        def connection
          @connection || Diametric::Persistence::REST.connection
        end

        def database
          @database || Diametric::Persistence::REST.database
        end

        def tempid(*e)
          EDN.tagged_element('db/id', e)
        end

        def transact(data)
          connection.transact(database, data)
        end

        def create_schema
          transact(schema)
        end

        def all
          Diametric::Query.new(self, nil, true).all
        end

        def first(conditions = {})
          where(conditions).first
        end

        def where(conditions = {})
          query = Diametric::Query.new(self, nil, true)
          query.where(conditions)
        end

        def filter(*filter)
          query = Diametric::Query.new(self, nil, true)
          query.filter(*filter)
        end

        def get(dbid, conn=nil, resolve=false)
          conn ||= connection
          res = conn.entity(database, dbid.to_i)

          # TODO tighten regex to only allow fields with the model name
          attrs = res.data.map { |attr_symbol, value|
            attr = attr_symbol.to_s.gsub(%r"^\w+/", '')
            [attr, value]
          }

          entity = self.new(Hash[*attrs.flatten])
          entity.dbid = dbid
          entity
        end

        def q(query, args, unused=nil)
          args.unshift(connection.db_alias(database))
          res = connection.query(query, args)
          res.data
        end
      end

      extend ClassMethods

      # Save the entity
      #
      # @example Save the entity.
      #   entity.save
      #
      # @return [ true, false ] True is success, false if not.
      def save
        return false unless valid?
        return true unless changed?

        self.dbid = self.dbid.to_i if self.dbid.class == String

        res = self.class.transact(tx_data)
        if dbid.nil? || dbid.is_a?(EDN::Type::Unknown)
          self.dbid = res.data[:tempids].values.first
        end

        @previously_changed = changes
        @changed_attributes.clear

        res
      end

      def to_edn
        self.dbid
      end

      def retract_entity(dbid)
        query = [[:"db.fn/retractEntity", dbid.to_i]]
        self.class.transact(query)
      end

      def method_missing(method_name, *args, &block)
        functions = self.instance_variable_get("@transaction_functions")
        if functions && functions.include?(method_name)
          return invoke_function(method_name, args)
        end
      end

      def invoke_function(method_name, args)
        params = args.dup
        conn = params.shift
        conn ||= Diametric::Persistence::REST.connection
        attribute_names = self.class.attribute_names
        params = params.map do |e|
          if attribute_names.include?(e)
            e = (self.class.prefix + "/" + e.to_s).to_sym
          else
            e
          end
        end
        conn.transact(Diametric::Persistence::REST.database, [[method_name, self.dbid, *params]])
        self.class.reify(self.dbid, conn)
      end
    end
  end
end
