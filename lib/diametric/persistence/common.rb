module Diametric
  module Persistence
    module Common
      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        def create_schema
          transact(schema)
        end

        def first(conditions = {})
          where(conditions).first
        end

        def where(conditions = {})
          query = Diametric::Query.new(self)
          query.where(conditions)
        end

        def filter(*filter)
          query = Diametric::Query.new(self)
          query.filter(*filter)
        end
      end
    end
  end
end
