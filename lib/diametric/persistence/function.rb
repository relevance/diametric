module Diametric
  module Persistence
    class Function
      # Defines a database function from given hash.
      #   The hash should have keys of :lang, :paramsm and :code.
      #   The hash can have optional keys of :requires and :imports.
      #
      # @example Defines a database function.
      #   Function.define_function({
      #     lang: :clojure,
      #     params: [:name],
      #     code: %{(str "Hello, " name)}})
      #
      # @return Diametric::Persistence::Function Function placeholder.
      def self.define_function(function_map)
        return Diametric::Persistence::Peer.function(function_map)
      end

      # Defines and saves a database function from given hash.
      #   The hash should have keys of :name, :lang, :paramsm and :code.
      #   The hash can have optional keys of :doc, :requires and :imports.
      #   The second argument is a connection to datomic. (optional)
      #
      # @example Defines and saves a database function in datomic.
      #   Function.create_function({
      #     name: :hello,
      #     lang: :clojure,
      #     params: [:name],
      #     code: %{(str "Hello, " name)}}, connection)
      #
      # @return result of the transaction
      def self.create_function(function_map, conn=nil)
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
        conn.transact([schema]).get
        function.name = name
        function
      end

      def name=(name)
        self.instance_variable_set("@name", name)
      end

      def name
        self.instance_variable_get("@name")
      end

      # Save the function.
      #
      # @example Save the function.
      #   function.save
      #
      # @return Diametric::Persistence::Listenable
      def save(name, doc=nil, conn=nil)
        conn ||= Diametric::Persistence::Peer.connect
        schema = [{:"db/id" => tempid(:"db.part/user"),
                  :"db/ident" => name.to_sym,
                  :"db/fn" => hello}]
        self.save(conn)
      end
    end
  end
end
