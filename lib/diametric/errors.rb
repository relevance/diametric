require 'diametric'

module Diametric
  module Errors
    
    class ValidationError < StandardError
      def initialize(entity)
        super(entity.errors.full_messages.join(", "))
      end
    end
    
  end
end