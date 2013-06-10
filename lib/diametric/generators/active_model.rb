require 'rails/generators/active_model'

module Diametric
  module Generators

    class ActiveModel < ::Rails::Generators::ActiveModel #:nodoc:
      def self.all(klass)
        "#{klass}.all"
      end

      def self.find(klass, params=nil, connection=nil, resolve=false)
        "#{klass}.get(#{params}, #{connection}, #{resolve})"
      end

      def self.build(klass, params=nil)
        if params
          "#{klass}.new(#{params})"
        else
          "#{klass}.new"
        end
      end

      def save
        "#{name}.save"
      end

      def update_attributes(params=nil)
        #"#{name}.update_attributes(#{params})"
        "#{name}.update(#{params})"
      end

      def errors
        "#{name}.errors"
      end

      def destroy
        "#{name}.destroy"
      end
    end

  end
end
