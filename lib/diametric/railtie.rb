# encoding: utf-8
require "diametric"
require "diametric/config"
require "rails"

module Rails
  module Diametric
    class Railtie < Rails::Railtie

      # TODO: Include?
      def self.generator
        :app_generators
      end

      # TODO
      # rake_tasks do
      #   load "mongoid/railties/database.rake"
      # end

      # Initialize Diametric. This will look for a diametric.yml in the config
      # directory and configure diametric appropriately.
      initializer "setup database" do
        config_file = Rails.root.join("config", "diametric.yml")
        if config_file.file?
          begin
            ::Diametric::Config.load!(config_file)
          rescue Exception => e
            handle_configuration_error(e)
          # TODO
          # rescue ::Mongoid::Errors::NoSessionsConfig => e
          #   handle_configuration_error(e)
          # rescue ::Mongoid::Errors::NoDefaultSession => e
          #   handle_configuration_error(e)
          # rescue ::Mongoid::Errors::NoSessionDatabase => e
          #   handle_configuration_error(e)
          # rescue ::Mongoid::Errors::NoSessionHosts => e
          #   handle_configuration_error(e)
          end
        end
      end

      # After initialization we will warn the user if we can't find a diametric.yml and
      # alert to create one.
      initializer "warn when configuration is missing" do
        config.after_initialize do
          unless Rails.root.join("config", "diametric.yml").file? || ::Diametric::Config.configured?
            puts "\nDiametric config not found. Create a config file at: config/diametric.yml"
            puts "to generate one run: rails generate diametric:config\n\n"
          end
        end
      end

      # Rails runs all initializers first before getting into any generator
      # code, so we have no way in the initializer to know if we are
      # generating a diametric.yml. So instead of failing, we catch all the
      # errors and print them out.
      def handle_configuration_error(e)
        puts "There is a configuration error with the current diametric.yml."
        puts e.message
      end
    end
  end
end
