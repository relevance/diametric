require 'diametric'
require 'edn'

module Diametric
  # +Query+ objects are used to generate Datomic queries, whether to
  # send via an external client or via the persistence API. The two
  # methods used to generate a query are +.where+ and +.filter+, both
  # of which are chainable. To get the query data and arguments for a
  # +Query+, use the +data+ method.
  #
  # If you are using a persistence API, you can ask +Query+ to get the
  # results of a Datomic query. +Diametric::Query+ is an
  # +Enumerable+. To get the results of a query, use +Enumerable+
  # methods such as +.each+ or +.first+. +Query+ also provides a
  # +.all+ method to run the query and get the results.
  class Query
    include Enumerable

    attr_reader :conditions, :filters, :filter_attrs, :filter_values, :model, :connection, :resolve

    # Create a new Datomic query.
    #
    # @param model [Entity] This model must include +Datomic::Entity+. Including
    #   a persistence module is optional.
    def initialize(model, connection_or_database=nil, resolve=false)
      @model = model
      @conditions = {}
      @filters = []
      @filter_attrs = []
      @filter_values = []
      @conn_or_db = connection_or_database
      @resolve = resolve
    end

    # Add conditions to your Datomic query. Conditions check for equality
    # against entity attributes. In addition, you can add conditions for
    # use as variables in filters.
    #
    # @example Looking for mice named Wilbur.
    #   Query.new(Mouse).conditions(:name => "Wilbur")
    #
    # @param conditions [Hash] Datomic variables and values.
    # @return [Query]
    def where(conditions)
      query = self.dup
      query.conditions = query.conditions.merge(conditions)
      query
    end

    # Add a filter to your Datomic query. Filters are known as expression clause
    # predicates in the {Datomic query documentation}[http://docs.datomic.com/query.html].
    #
    # A filter can be in one of two forms. In the first, you pass a
    # series of arguments. Any Ruby symbol given in this form will be
    # converted to a EDN symbol. If the symbol is the same as one of
    # the queried model's attributes or as a key passed to +where+, it
    # will be prefixed with a +?+ so that it becomes a Datalog
    # variable. In the second form, you pass
    # {EDN}[https://github.com/relevance/edn-ruby] representing a
    # Datomic predicate to +filter+. No conversion is done on this
    # filter and it must be an EDN list.
    #
    # @example Passing arguments to be converted.
    #   query.filter(:>, :age, 21)                # REST
    #   query.filter(connection, :>, :age, 21)    # Peer
    #
    # @example Passing EDN, which will not be converted.
    #   query.filter(EDN::Type::List.new(EDN::Type::Symbol(">"),
    #                                    EDN::Type::Symbol("?age"),
    #                                    21))
    #   # or, more simply
    #   query.filter(~[~">", ~"?age", 21])
    #
    # @param filter [Array] Either one +EDN::Type::List+ or a number of arguments
    #   that will be converted into a Datalog query.
    # @return [Query]
    def filter(*filter)
      return peer_filter(*filter) if self.model.instance_variable_get("@peer")
      query = self.dup

      if filter.first.is_a?(EDN::Type::List)
        filter = filter.first
      else
        filter = filter.map { |e| convert_filter_element(e) }
        filter = EDN::Type::List.new(*filter)
      end
      query.filters += [[filter]]
      query
    end

    def peer_filter(*filter)
      query = self.dup
      query.filter_attrs += (self.model.attribute_names & filter)
      filter = filter.map do |e|
        if e.is_a? Symbol
          convert_filter_element(e)
        elsif e.is_a? String
          e
        else
          query.filter_values << e
          ~"?#{query.filter_attrs.last.to_s}value"
        end
      end
      filter = EDN::Type::List.new(*filter)
      query.filters << [Diametric::Persistence::Utils.read_string(filter.to_edn)]
      query
    end


    # Loop through the query results. In order to use +each+, your model *must*
    # include a persistence API. At a minimum, it must have a +.q+ method that
    # returns an +Enumerable+ object.
    #
    # @yield [Entity] An instance of the model passed to +Query+.
    def each
      # TODO check to see if the model has a `.q` method and give
      # an appropriate error if not.
      res = model.q(*data, @conn_or_db)
      collapse_results(res).each do |entity|
        if @resolve
          yield model.reify(entity.first, @conn_or_db, @resolve)
        elsif self.model.instance_variable_get("@peer")
          yield entity
        # The map is for compatibility with Java peer persistence.
        # TODO remove if possible
        else
          yield model.from_query(entity.map { |x| x }, @conn_or_db, @resolve)
        end
      end
    end

    # Return all query results.
    #
    # @return [Array<Entity>] Query results.
    #         or Set([Array<dbid>]) for Peer without resolve option
    def all(conn_or_db=@conn_or_db)
      if self.model.instance_variable_get("@peer") && !@resolve
        model.q(*data, conn_or_db)
      else
        map { |x| x }
      end
    end

    # Create a Datomic query from the conditions and filters passed to this
    # +Query+ object.
    #
    # @return [Array(Array, Array)] The first element of the array returned
    #   is the Datomic query composed of Ruby data. The second element is
    #   the arguments that used with the query.
    def data
      return peer_data if self.model.instance_variable_get("@peer")

      vars = model.attribute_names.map { |attribute| ~"?#{attribute}" }

      from = conditions.map { |k, _| ~"?#{k}" }

      clauses = model.attribute_names.map { |attribute|
        [~"?e", model.namespace(model.prefix, attribute), ~"?#{attribute}"]
      }
      clauses += filters

      args = conditions.map { |_, v| v }

      query = [
        :find, ~"?e", *vars,
        :in, ~"\$", *from,
        :where, *clauses
      ]

      [query, args]
    end

    def peer_data
      if conditions.empty? && filters.empty?
        args = [model.prefix]
        query = <<-EOQ
[:find ?e
 :in $ [?include-ns ...]
 :where
 [?e ?aid ?v]
 [?aid :db/ident ?a]
 [(namespace ?a) ?ns]
 [(= ?ns ?include-ns)]]
EOQ
      else
        from = conditions.map do |k, v|
          if v.kind_of? Array
            [~"?#{k}",
             Diametric::Persistence::Utils.read_string("...")]
          else
            ~"?#{k}"
          end
        end

        keys = conditions.keys
        unless filter_attrs.empty?
          from += filter_attrs.inject([]) { |memo, key| memo << ~"?#{key}value"; memo }
          keys += filter_attrs
        end
        keys.uniq!

        clauses = keys.map { |attribute|
          [~"?e", model.namespace(model.prefix, attribute), ~"?#{attribute}"]
        }
        clauses += filters

        args = conditions.map { |_, v| v }
        args += filter_values

        query = [
                 :find, ~"?e",
                 :in, ~"\$", from.flatten(1),
                 :where, *clauses
                ]
      end
      [query, args]
    end

    protected

    def conditions=(conditions)
      @conditions = conditions
    end

    def filters=(filters)
      @filters = filters
    end

    def filter_attrs=(filter_attrs)
      @filter_attrs = filter_attrs
    end

    def filter_values=(filter_values)
      @filter_values = filter_values
    end

    def convert_filter_element(element)
      if element.is_a?(Symbol)
        if model.attribute_names.include?(element) || @conditions.keys.include?(element)
          EDN::Type::Symbol.new("?#{element}")
        else
          EDN::Type::Symbol.new(element.to_s)
        end
      else
        element
      end
    end

    def collapse_results(res)
      return res if self.model.instance_variable_get("@peer")

      res.group_by(&:first).map do |dbid, results|
        # extract dbid from results
        # NOTE: we prefer to_a.drop(1) over block arg decomposition because
        #       result may be a Java::ClojureLang::PersistentVector
        results = results.map {|result| result.to_a.drop(1) }

        unless results.flatten.empty?
          # Group values from all results into one result set
          # [["b", 123], ["c", 123]] #=> [["b", "c"], [123, 123]]
          grouped_values = results.transpose
          attr_grouped_values = grouped_values[0...model.attributes.size]
          enum_grouped_values = grouped_values[model.attributes.size..-1]

          # Attach attribute names to each collection of values
          # => [[:letters, ["b", "c"]], [:number, [123, 123]]]
          attr_to_values = model.attributes.keys.zip(attr_grouped_values)

          # Retain cardinality/many attributes as a collection,
          # but pick only one value for cardinality/one attributes
          collapsed_values = attr_to_values.map do |attr, values|
            if model.attributes[attr][:cardinality] == :many
              values
            elsif model.attributes[attr][:value_type] == "ref" &&
                model.enum_names.include?(attr)
              enum_grouped_values.shift.first
            else
              values.first
            end
          end

          # Returning a singular result for each dbid
          [dbid, *collapsed_values]
        else
          [dbid]
        end
      end
    end
  end
end
