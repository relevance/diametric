require 'diametric/persistence/common'

module Diametric
  module Persistence
    module Peer

      def save(connection=nil)
        return false unless valid?
        return true unless changed?
        connection ||= Diametric::Persistence::Peer.connect

        parsed_data = []
        parse_tx_data(tx_data, parsed_data)
        map = connection.transact(parsed_data).get
        self.instance_variable_set("@tx_map", map)

        if @dbid.nil? || @dbid.to_s =~ /-\d+/
          @dbid = Diametric::Persistence::Peer.resolve_tempid(map, @dbid)
        end

        @previously_changed = changes
        @changed_attributes.clear
        map
      end

      def parse_tx_data(data, result)
        queue = []
        data.each do |c_hash|
          hash = {}
          c_hash.each do |c_key, c_value|
            if c_value.respond_to?(:tx_data)
              c_value.dbid = c_value.tempid
              hash[c_key] = c_value.dbid
              queue << c_value.tx_data.first
            else
              hash[c_key] = c_value
            end
          end
          result << hash
        end
        parse_tx_data(queue, result) unless queue.empty?
      end

      def retract_entity(dbid)
        Diametric::Persistence::Peer.retract_entity(dbid)
      end

      module ClassMethods
        def get(dbid)
          entity = self.new
          datomic_entity = Diametric::Persistence::Peer.get(dbid)
          entity.attribute_names.each do |name|
            entity.instance_variable_set("@#{name.to_s}", datomic_entity.get(self.namespace(self.prefix, name)))
          end
          entity.dbid = dbid
          entity
        end

        def q(query, args, connection=nil)
          connection ||= Diametric::Persistence::Peer.connect
          db = connection.db

          results = Diametric::Persistence::Peer.q(query, db, args)
          # Diametric query expects the first element of each array in
          # results is dbid. Wraps dbid here by
          # Diametric::Persistence::Object to make it consistent
          results.each do |r|
            r[0] = Diametric::Persistence::Object.new(r[0])
          end
          results
        end
      end
    end
  end
end
