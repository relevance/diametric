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

        resolve_changes([self], map)

        map
      end

      def resolve_tempid(map, id)
        if id.to_s =~ /-\d+/
          return Diametric::Persistence::Peer.resolve_tempid(map, id)
        end
        return id
      end

      def parse_tx_data(data, result)
        queue = []
        data.each do |c_hash|
          hash = {}
          c_hash.each do |c_key, c_value|
            if c_value.respond_to?(:tx_data)
              if c_value.tx_data.empty?
                hash[c_key] = c_value.dbid
              else
                c_value.dbid = c_value.tempid
                hash[c_key] = c_value.dbid
                queue << c_value.tx_data.first
              end
            else
              hash[c_key] = c_value
            end
          end
          result << hash
        end
        parse_tx_data(queue, result) unless queue.empty?
      end

      def resolve_changes(parents, map)
        queue = []
        parents.each do |child|
          child.attributes.each do |a_key, a_val|
            if a_val.respond_to?(:tx_data)
              queue << a_val
            end
          end
          child.instance_variable_set("@previously_changed", child.changes)
          child.changed_attributes.clear
          child.dbid = resolve_tempid(map, child.dbid)
          child.instance_variable_set("@tx_map", map)
        end
        resolve_changes(queue, map) unless queue.empty?
      end

      def retract_entity(dbid)
        Diametric::Persistence::Peer.retract_entity(dbid)
      end

      module ClassMethods
        def get(dbid)
          entity = self.new
          dbid = dbid.to_i if dbid.is_a?(String)
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
