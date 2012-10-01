require "diametric/version"

module Diametric
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:extend, ClassMethods)

    # TODO set up :db/id
  end

  module ClassMethods
    def attr(name, opts)
    end

    def schema
    end

    def query(params)
    end

    def from_query(query_results)
    end
  end

  module InstanceMethods
    def initialize(params = {})
    end

    def transact(*attrs)
    end
  end
end
