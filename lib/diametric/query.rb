require 'diametric'

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

    attr_reader :conditions, :filters, :model

    # Create a new Datomic query.
    #
    # @param model [Entity] This model must include +Datomic::Entity+. Including
    #   a persistence module is optional.
    def initialize(model)
      @model = model
      @conditions = {}
      @filters = []
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
    #   query.filter(:>, :age, 21)
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

    # Loop through the query results. In order to use +each+, your model *must*
    # include a persistence API. At a minimum, it must have a +.q+ method that
    # returns an +Enumerable+ object.
    #
    # @yield [Entity] An instance of the model passed to +Query+.
    def each
      # TODO check to see if the model has a `.q` method and give
      # an appropriate error if not.
      res = model.q(*data)
      res.each do |entity|
        # The map is for compatibility with Java persistence.
        # TODO remove if possible
        yield model.from_query(entity.map { |x| x })
      end
    end

    # Return all query results.
    #
    # @return [Array<Entity>] Query results.
    def all
      map { |x| x }
    end

    # Create a Datomic query from the conditions and filters passed to this
    # +Query+ object.
    #
    # @return [Array<Array, Array>] The first element of the array returned
    #   is the Datomic query composed of Ruby data. The second element is
    #   the arguments that used with the query.
    def data
      vars = model.attributes.map { |attribute, _, _| ~"?#{attribute}" }

      from = conditions.map { |k, _| ~"?#{k}" }

      clauses = model.attributes.map { |attribute, _, _|
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

    protected

    def conditions=(conditions)
      @conditions = conditions
    end

    def filters=(filters)
      @filters = filters
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
  end
end
