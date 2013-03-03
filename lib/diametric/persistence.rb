module Diametric
  # Persistence is the main entry point for adding persistence to your diametric entities.
  module Persistence
    class << self; attr_reader :conn_type; end
    autoload :REST, 'diametric/persistence/rest'

    # Establish a base connection for your application that is used unless specified otherwise. This method can
    # establish connections in either REST or peer mode, depending on the supplied options.
    #
    # @example Connecting in peer-mode (JRuby required)
    #   Diametric::Persistence.establish_base_connection({:uri => "datomic:free://localhost:4334/my-db"})
    #
    # @example Connecting in REST-mode
    #   Diametric::Persistence.establish_base_connection({:uri      => "http://localhost:9000/",
    #                                                     :database => "my-db",
    #                                                     :storage  => "my-dbalias"})
    def self.establish_base_connection(options)
      @_persistence_class = persistence_class(options[:uri])
      @_persistence_class.connect(options)
    end

    # Including +Diametric::Persistence+ after establishing a base connection will include
    # the appropriate Persistence class ({REST} or {Peer})
    def self.included(base)
      base.send(:include, @_persistence_class) if @_persistence_class
    end

    def self.peer?
      @conn_type == :peer
    end

    def self.rest?
      @conn_type == :rest
    end

    private

    def self.persistence_class(uri)
      if uri =~ /^datomic:/
        @conn_type = :peer
        Peer
      else
        @conn_type = :rest
        REST
      end
    end
  end
end
