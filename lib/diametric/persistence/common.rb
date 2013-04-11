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
          valid_keys = attribute_names + [:id]
          new_attributes.each do |key, value|
            if valid_keys.include? key.to_sym
              self.send("#{key}=", value)
            end
          end
        end
        
        # Save the entity. If a validation error occurs an error will get raised.
        #
        # @example Save the entitiy.
        #   entity.save!
        #
        # @return [ true, false ] True if validation passed.
        def save!
          unless save
            self.class.fail_validate!(self) unless errors.empty?
          end
          return true
        end
      end

      module ClassMethods
        def create_schema(connection=nil)
          if self.instance_variable_get("@peer")
            connection ||= Diametric::Persistence::Peer.connect
            connection.transact(schema)
          else
            transact(schema)
          end
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
