require "diametric/version"
require "diametric/entity"
require "diametric/query"
require "diametric/persistence"
require "diametric/errors"

require 'diametric/config'

if defined?(RUBY_ENGINE) && RUBY_ENGINE = "jruby"
  require 'lock_jar'
  lockfile = File.join(File.dirname(__FILE__), "..", "Jarfile.lock")
  LockJar.load(lockfile)

  require 'diametric_service.jar'
  reuqire 'diametric/diametric'
end

if defined?(Rails)
  require 'diametric/railtie'
end

# Diametric is a library for building schemas, queries, and
# transactions for Datomic from Ruby objects. It is also used to map
# Ruby objects as entities into a Datomic database.
module Diametric
  extend Diametric::Config
end
