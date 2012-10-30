require 'diametric'
require 'diametric/persistence/query'
require 'datomic/client'

module Diametric
  module Persistence
    module REST
      @persisted_classes = Set.new

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)

        @persisted_classes.add(base)
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

        def create_schema
          transact(schema)
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

        def first(conditions = {})
          where(conditions).first
        end

        def where(conditions = {})
          query = Query.new(self)
          query.where(conditions)
        end

        def filter(*filter)
          query = Query.new(self)
          query.filter(*filter)
        end

        def q(conditions = {}, filters = [])
          query, args = query_data(conditions, filters)
          args.unshift(connection.db_alias(database))
          res = connection.query(query, args)
          res.data
        end
      end

      extend ClassMethods

      module InstanceMethods
        def id=(dbid)
          self.dbid = dbid
        end

        def save
          res = self.class.transact(tx_data)
          if dbid.nil?
            self.dbid = res.data[:tempids].values.first
          end
          res
        end

        # == checks to see if the two objects are the same entity in Datomic.
        def ==(other)
          return false if self.dbid.nil?
          return false unless other.respond_to?(:dbid)
          return false unless self.dbid == other.dbid
          true
        end

        # eql? checks to see if the two objects are of the same type, are the same
        # entity, and have the same attribute values.
        def eql?(other)
          return false unless self == other
          return false unless self.class == other.class

          attribute_names.each do |attr|
            return false unless self.send(attr) == other.send(attr)
          end

          true
        end
      end
    end
  end
end
