module Diametric
  module Persistence
    module Common
      def self.included(base)
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

        def transaction_functions
          functions = self.instance_variable_get("@transaction_functions")
          unless functions
            functions = ::Set.new
            self.instance_variable_set("@transaction_functions", functions)
          end
          functions
        end
      end
    end
  end
end
