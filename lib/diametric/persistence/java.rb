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

        def clj
          @clj ||= JRClj.new
        end
      end

      extend ClassMethods

      module InstanceMethods
        include_package "datomic"

        def clj
          self.class.clj
        end

        def connection
          self.class.connection
        end

        alias :conn :connection

        def save
          res = self.class.transact(tx_data)
          if dbid.nil?
            self.dbid = Peer.resolve_tempid(res[:"db-after".to_clj], res[:tempids.to_clj], clj.edn_convert(tempid))
          end
          res
        end
      end
    end
  end
end
