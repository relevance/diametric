unless defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  raise "This module requires the use of JRuby."
end

require 'java'
require 'jbundler'
# This is here to ensure it is loaded before Datomic is used.
java_import "com.google.common.cache.CacheBuilder"
require 'jrclj'
java_import "clojure.lang.Keyword"

module Diametric
  module Persistence
    module Java
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        include_package "datomic"

        def create_database(uri)
          Peer.create_database(uri)
        end

        def connect(uri)
          @connection = Peer.connect(uri)
        end

        def connection
          @connection || Diametric::Persistence::Java.connection
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
          res = q(conditions)
          from_query(res.first.map { |x| x })
        end

        def where(conditions = {})
          res = q(conditions)
          res.map { |entity|
            from_query(entity.map { |x| x })
          }
        end

        def q(conditions = {})
          query, args = query_data(conditions)
          Peer.q(clj.edn_convert(query), connection.db, *args)
        end

        def clj
          @clj ||= JRClj.new
        end
      end

      extend ClassMethods

      module InstanceMethods
        include_package "datomic"

        def connection
          self.class.connection
        end

        alias :conn :connection

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
