module Diametric
  module Persistence
    module Common
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def update_attributes(new_attributes)
          assign_attributes(new_attributes)
          save
        end

        def assign_attributes(new_attributes)

        end
      end

      module ClassMethods
        def create_schema
          transact(schema)
        end

        def all
          Diametric::Query.new(self).all
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
