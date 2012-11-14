unless defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  raise "This module requires the use of JRuby."
end

require 'diametric'
require 'diametric/persistence/common'

require 'java'
require 'lock_jar'
lockfile = File.expand_path( "../../../../Jarfile.lock", __FILE__ )
# Loads the classpath with Jars from the lockfile
LockJar.load(lockfile)

require 'jrclj'
java_import "clojure.lang.Keyword"

module Diametric
  module Persistence
    module Peer
      include_package "datomic"

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
        include_package "datomic"

        def connect(options = {})
          uri = options[:uri]
          Java::Datomic::Peer.create_database(uri)
          @connection = Java::Datomic::Peer.connect(uri)
        end

        def disconnect
          @connection = nil
        end

        def connection
          @connection || Diametric::Persistence::Peer.connection
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

        def q(query, args)
          Java::Datomic::Peer.q(clj.edn_convert(query), connection.db, *args)
        end

        def clj
          @clj ||= JRClj.new
        end
      end

      extend ClassMethods

      def save
        return false unless valid?
        return true unless changed?

        res = self.class.transact(tx_data)
        if dbid.nil?
          self.dbid = Java::Datomic::Peer.resolve_tempid(
                                                  res[:"db-after".to_clj],
                                                  res[:tempids.to_clj],
                                                  self.class.clj.edn_convert(tempid))
        end

        @previously_changed = changes
        @changed_attributes.clear

        res
      end

      def to_edn
        self.dbid
      end
    end
  end
end
