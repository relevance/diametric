require 'diametric/config/environment'
require 'diametric/persistence'

module Diametric
  # Program-level configuration services including configuration loading and base connections.
  module Config
    extend self

    # The current configuration Diametric will use in {#connect!}
    #
    # @return [Hash]
    def configuration
      @configuration ||= {}
    end

    # Determine if Diametric has been configured
    #
    # @return [Boolean]
    def configured?
      configuration.present?
    end

    # Load settings from a compliant diametric.yml file and make a connection. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # See {Persistence} for valid options.
    #
    # @example Configure Diametric.
    #   Diametric.load_and_connect!("/path/to/diametric.yml")
    #
    # @param [ String ] path The path to the file.
    # @param [ String, Symbol ] environment The environment to load.
    def load_and_connect!(path, environment = nil)
      settings = Environment.load_yaml(path, environment)
      @configuration = settings.with_indifferent_access
      connect!(configuration)
      peer_setup if Diametric::Persistence.peer?
      configuration
    end

    # Establish a base connection from the supplied configuration hash.
    #
    # @param [ Hash ] configuration The configuration of the database to connect to. See {Persistence.establish_base_connection} for valid options.
    def connect!(configuration)
      ::Diametric::Persistence.establish_base_connection(configuration)
    end

    private
    def peer_setup
      load File.join(File.dirname(__FILE__), '..', 'tasks', 'create_schema.rb')
      Rake::Task["diametric:create_schema_for_peer"].invoke
    end
  end
end
