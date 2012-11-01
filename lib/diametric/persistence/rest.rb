require 'diametric'
require 'diametric/persistence/common'
require 'datomic/client'

module Diametric
  module Persistence
    module REST
      @connection = nil
      @persisted_classes = Set.new

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
        def connect(uri, dbalias, database)
          @uri = uri
          @dbalias = dbalias
          @database = database

          @connection = Datomic::Client.new(uri, dbalias)
          @connection.create_database(database)
        end

        def connection
          @connection || Diametric::Persistence::REST.connection
        end

        def database
          @database || Diametric::Persistence::REST.database
        end

        def transact(data)
          connection.transact(database, data)
        end

        def get(dbid)
          res = connection.entity(database, dbid)

          # TODO tighten regex to only allow fields with the model name
          attrs = res.data.map { |attr_symbol, value|
            attr = attr_symbol.to_s.gsub(%r"^\w+/", '')
            [attr, value]
          }

          entity = self.new(Hash[*attrs.flatten])
          entity.dbid = dbid
          entity
        end

        def q(query, args)
          args.unshift(connection.db_alias(database))
          res = connection.query(query, args)
          res.data
        end
      end

      extend ClassMethods

      def save
        return unless changed?

        res = self.class.transact(tx_data)
        if dbid.nil?
          self.dbid = res.data[:tempids].values.first
        end

        @previously_changed = changes
        @changed_attributes.clear

        res
      end
    end
  end
end
