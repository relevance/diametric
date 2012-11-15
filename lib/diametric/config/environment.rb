module Diametric
  module Config

    # Encapsulates logic for getting environment information.
    #
    # This is nearly a word-for-word copy of {http://github.com/mongoid/mongoid Mongoid}'s {https://github.com/mongoid/mongoid/blob/master/lib/mongoid/config/environment.rb lib/mongoid/config/environment.rb} file.
    # Thanks!
    module Environment
      extend self

      # Get the name of the environment that we are running under. This first
      # looks for Rails, then Sinatra, then a RACK_ENV environment variable,
      # and if none of those are found raises an error.
      #
      # @example Get the env name.
      #   Environment.env_name
      #
      # @raise [ "No environment specified" ] If no environment was set.
      #
      # @return [ String ] The name of the current environment.
      def env_name
        return Rails.env if defined?(Rails)
        return Sinatra::Base.environment.to_s if defined?(Sinatra)
        ENV["RACK_ENV"] || ENV["DIAMETRIC_ENV"] || raise("No environment specified")
      end

      # Load the yaml from the provided path and return the settings for the
      # current environment.
      #
      # @example Load the yaml.
      #   Environment.load_yaml("/work/diametric.yml")
      #
      # @param [ String ] path The location of the file.
      #
      # @return [ Hash ] The settings.
      def load_yaml(path, environment = nil)
        env = environment ? environment.to_s : env_name
        YAML.load(ERB.new(File.new(path).read).result)[env]
      end
    end
  end
end
