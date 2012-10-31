require 'diametric'

module Diametric
  class Query
    include Enumerable

    attr_reader :conditions, :filters, :model

    def initialize(model)
      @model = model
      @conditions = {}
      @filters = []
    end

    def where(conditions)
      query = self.dup
      query.conditions = query.conditions.merge(conditions)
      query
    end

    # Add a filter to your Datomic query. Filters are known as expression clause
    # predicates in the {Datomic query documentation}[http://docs.datomic.com/query.html].
    #
    # A filter can be in one of two forms. In the first, you pass
    # {EDN}[https://github.com/relevance/edn-ruby] representing a Datomic
    # predicate to +filter+. No conversion is done on this filter and it must be
    # an EDN list. In the second form, you pass a series of arguments. Any Ruby
    # symbol given in this form will be converted to a EDN symbol. If the symbol
    # is the same as one of the queried model's attributes or as a key passed
    # to +where+, it will be prefixed with a +?+ so that it becomes a Datalog
    # variable.
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

    def all
      map { |x| x }
    end

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

    private

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
