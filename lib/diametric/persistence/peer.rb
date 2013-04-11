require 'diametric/persistence/common'

module Diametric
  module Persistence
    module Peer

      def save(connection=nil)
        return false unless valid?
        return true unless changed?
        connection ||= Diametric::Persistence::Peer.connect

        map = connection.transact(re_tx_data).get

        if @dbid.nil? || @dbid.to_s =~ /-\d+/
          @dbid = Diametric::Persistence::Peer.resolve_tempid(map, @dbid)
        end

        @previously_changed = changes
        @changed_attributes.clear
        map
      end

      def re_tx_data
        ary = []
        tx_data.each do |e|
          hash = {}
          e.each do |k,v|
            if v.respond_to?(:tx_data)
              v.dbid = v.tempid
              hash[k]=v.dbid
              ary << v.tx_data.first
            else
              hash[k]=v
            end
          end
          ary << hash
        end
        ary
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
