require 'diametric/entity'

module Diametric
  module Persistence
    def self.included(base)
      if !base.ancestors.include?(Diametric::Entity)
        base.send(:include, Diametric::Entity)
      end
      base.send(:extend, ClassMethods)
    end

    def self.connect(url, db_alias)
    end

    module ClassMethods
      def database
        @database
      end

      def database=(database)
        @database = database
      end

      # Create database unless it already exists.
      def create_database
      end
    end

    def update_attribute(attribute, value)
    end

    def update_attributes(new_attributes)
    end

    # Persist entity to Datomic.
    def save
    end

    # Retract all facts about the entity in Datomic
    def retract
    end

    alias_method :destroy, :retract
  end
end
