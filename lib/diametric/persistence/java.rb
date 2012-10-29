unless defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  raise "This module requires the use of JRuby."
end

require 'java'
require 'jbundler'
# This is here to ensure it is loaded before Datomic is used.
java_import "com.google.common.cache.CacheBuilder"
require 'diametric/persistence/jrclj'
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
          data = clj.read_string(data.to_edn)
          res = connection.transact(data)

          # r = res.get
          # r.keys.last => :tempids
          # r[r.keys.last] => {-9223367638809264705=>63}
          # r[r.keys.last].to_a.first.last => 63
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
          binding.pry
        end
      end
    end
  end
end
