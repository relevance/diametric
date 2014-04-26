module Diametric
  module Persistence
    class Function
      # Defines and saves a transaction or database function from given hash.
      #   The hash should have keys of :name, :lang, :params and :code.
      #   The hash can have optional keys of :doc, :requires and :imports.
      #   The second argument is a connection to datomic. (optional)
      #
      # @example Defines and saves a database function in datomic.
      #   Function.create({
      #     name: :inc_fn
      #     lang: :clojure,
      #     params: [:db, :id, :attr, :amount],
      #     code: %{(let [e (datomic.api/entity db id) orig (attr e 0)]
      #            [[:db/add id attr (+ orig amount) ]])},
      #     connection)
      #
      # @return result of the updated entity.
      def self.create(function_map, conn)
        if conn && conn.is_a?(Diametric::Persistence::Connection)
          self.extend(Diametric::Persistence::PeerFunction)
        else
          conn = Diametric::Persistence::REST.connection
          self.extend(Diametric::Persistence::RestFunction)
        end
        self.create_function(function_map, conn)
      end
    end
  end
end
