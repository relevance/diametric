module Diametric
  module Persistence
    module PeerFunction
      def create_function(function_map, conn=nil)
        conn ||= Diametric::Persistence::Peer.connection
        map = function_map.dup
        name = map.delete(:name)
        doc = map.delete(:doc)
        function =  Diametric::Persistence::Peer.function(map)
        schema = {:"db/id" => Diametric::Persistence::Peer.tempid(:"db.part/user"),
                  :"db/ident" => name.to_sym,
                  :"db/fn" => function}
        if doc
          schema.merge!({:"db/doc" => doc})
        end
        result = conn.transact([schema]).get
      end
    end
  end
end
