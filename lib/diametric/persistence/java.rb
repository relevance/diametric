unless defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  raise "This module requires the use of JRuby."
end

require 'diametric'

require 'java'
require 'lock_jar'
lockfile = File.expand_path( "../../../../Jarfile.lock", __FILE__ )
# Loads the classpath with Jars from the lockfile
LockJar.load(lockfile)

require 'jrclj'
java_import "clojure.lang.Keyword"

module Diametric
  module Persistence
    module Java
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
        include_package "datomic"

        def connect(uri)
          Peer.create_database(uri)
          @connection = Peer.connect(uri)
        end

        def connection
          @connection || Diametric::Persistence::Java.connection
        end

        def create_schema
          transact(schema)
        end

        def transact(data)
          data = clj.edn_convert(data)
          res = connection.transact(data)
          res.get
        end

        def get(dbid)
          entity_map = connection.db.entity(dbid)
          attrs = entity_map.key_set.map { |attr_keyword|
            attr = attr_keyword.to_s.gsub(%r"^:\w+/", '')
            value = entity_map.get(attr_keyword)
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
          query = Diametric::Query.new(self)
          query.where(conditions)
          query
        end

        def q(query, args)
          Peer.q(clj.edn_convert(query), connection.db, *args)
        end

        def clj
          @clj ||= JRClj.new
        end
      end

      extend ClassMethods

      module InstanceMethods
        include_package "datomic"

        def save
          res = self.class.transact(tx_data)
          if dbid.nil?
            self.dbid = Peer.resolve_tempid(
                                     res[:"db-after".to_clj],
                                     res[:tempids.to_clj],
                                     clj.edn_convert(tempid))
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

        private

        def clj
          self.class.clj
        end
      end
    end
  end
end
