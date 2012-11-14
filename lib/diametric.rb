require "diametric/version"
require "diametric/entity"
require "diametric/query"
require "diametric/persistence"

require 'diametric/config'

if defined?(Rails)
  require 'diametric/railtie'
end

# Diametric is a library for building schemas, queries, and
# transactions for Datomic from Ruby objects. It is also used to map
# Ruby objects as entities into a Datomic database.
module Diametric
  extend Diametric::Config
end
