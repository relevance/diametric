require 'diametric'

module Diametric
  module Persistence
    class Query
      include Enumerable

      def initialize(model)
        @model = model
        @conditions = {}
        @filters = []
      end

      def where(conditions)
        @conditions = @conditions.merge(conditions)
        self
      end

      def filter(*filter)
        if filter.first.is_a?(EDN::Type::List)
          filter = filter.first
        else
          filter = filter.map { |e| convert_filter_element(e) }
          filter = EDN::Type::List.new(*filter)
        end

        @filters << [filter]

        self
      end

      def each
        res = @model.q(@conditions, @filters)
        res.each do |entity|
          # The map is for compatibility with Java persistence.
          # TODO remove if possible
          yield @model.from_query(entity.map { |x| x })
        end
      end

      def all
        map { |x| x }
      end

      private

      def convert_filter_element(element)
        if element.is_a?(Symbol)
          if @model.attribute_names.include?(element)
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
end
