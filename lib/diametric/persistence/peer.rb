module Diametric
  module Persistence
    module Peer

      def save
        return false unless valid?
        return true unless changed?
        map = Diametric::Persistence::Peer.connect.transact(tx_data).get

        if @dbid.nil? || @dbid.to_s =~ /-\d+/
          @dbid = Diametric::Persistence::Peer.resolve_tempid(map, @dbid)
        end

        @previously_changed = changes
        @changed_attributes.clear
        map
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

        def q(query, args)
          db = Diametric::Persistence::Peer.connect.db
          Diametric::Persistence::Peer.q(query, db, args)
        end
      end
    end
  end
end
