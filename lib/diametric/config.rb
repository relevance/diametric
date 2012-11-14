require 'diametric/config/environment'
require 'diametric/persistence'

# TODO: Require connection-mode
module Diametric
  module Config
    extend self

    def configuration
      @configuration ||= {}
    end

    # TODO: Flesh-out and document
    def configured?
      configuration.present?
    end

    # From a hash of settings, load all the configuration.
    #
    # @example Load the configuration.
    #   config.load_configuration(settings)
    #
    # @param [ Hash ] settings The configuration settings.
    def load_configuration(settings)
      @configuration = settings.with_indifferent_access
    end

    # Load the settings from a compliant mongoid.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Mongoid.
    #   Mongoid.load!("/path/to/mongoid.yml")
    #
    # @param [ String ] path The path to the file.
    # @param [ String, Symbol ] environment The environment to load.
    #
    # @since 2.0.1
    def load!(path, environment = nil)
      settings = Environment.load_yaml(path, environment)
      load_configuration(settings) if settings.present?
      connect!
      configuration
    end

    # TODO: document
    def connect!(config = configuration)
      unless config.present?
        raise "Diametric has not been configured. Add a config to config/diametric.yml or run rails g diametric:config to make one"
      end

      ::Diametric::Persistence.connect(config)
    end
  end
end
