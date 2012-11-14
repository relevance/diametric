module Diametric
  module Persistence
    extend self

    def connect(options)
      mode = options.delete(:mode)
      persistence_class(mode).connect(options)
    end

    private

    def persistence_class(mode)
      mode = mode.to_sym

      case
      when :rest
        require 'diametric/persistence/rest'
        Diametric::Persistence::REST
      when :peer
        require 'diametric/persistence/peer'
        Diametric::Persistence::Peer
      end
    end
  end
end
