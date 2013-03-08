module Diametric
  module Persistence
    module Peer

      def save
        return false unless valid?
        return true unless changed?
        map = Diametric::Persistence::Peer.connect.transact(tx_data).get

        @dbid = Diametric::Persistence::Peer.resolve_tempid(map, @dbid)

        @previously_changed = changes
        @changed_attributes.clear
        map

      end
    end
  end
end
