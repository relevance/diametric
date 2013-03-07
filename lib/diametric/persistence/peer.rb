module Diametric
  module Persistence
    module Peer

      def save
        puts "#{self} called save"
        puts "tx_data: #{self.tx_data}"

        return false unless valid?
        return true unless changed?
        map = self.class.connect.transact(tx_data)
        if dbid.nil?
          self.dbid = self.class.resolve_tempid(map, tempid)
        end
        @previously_changed = changes
        @changed_attributes.clear
        map

      end
    end
  end
end
