module Diametric
  module Persistence
    module RestFunction
      def create_function(function_map, unused)
        conn = Diametric::Persistence::REST.connection
        map = function_map.dup
        name = map.delete(:name)
        doc = map.delete(:doc)
        schema = {:"db/id" => Diametric::Persistence::REST.tempid(:"db.part/user"),
                  :"db/ident" => name.to_sym}
        schema.merge!({:"db/fn" => EDN.tagged_element('db/fn', map)})
        if doc
          schema.merge!({:"db/doc" => doc})
        end
        result = conn.transact(Diametric::Persistence::REST.database, [schema]) # fails
      end
    end
  end
end
