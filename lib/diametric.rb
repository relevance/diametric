require "diametric/version"
require "diametric/entity"
require "diametric/query"
require "diametric/persistence"
require "diametric/errors"

require 'diametric/config'

def is_jruby?
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    true
  else
    false
  end
end

if is_jruby?
  require 'lock_jar'
  lockfile = File.join(File.dirname(__FILE__), "..", "Jarfile.lock")
  unless File.exists?(lockfile)
    current_dir = Dir.pwd
    Dir.chdir(File.dirname(lockfile))
    LockJar.lock
    LockJar.install
    Dir.chdir(current_dir)
  end
  LockJar.load(lockfile)

  require 'diametric_service.jar'
  require 'diametric/diametric'
  require 'diametric/persistence/peer'
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
