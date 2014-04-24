require "diametric/version"
require "diametric/entity"
require "diametric/associations/collection"
require "diametric/query"
require "diametric/persistence"
require "diametric/persistence/function"
require "diametric/persistence/rest_function"
require "diametric/persistence/peer_function"
require "diametric/bucket"
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
  jar_file = File.join(File.dirname(__FILE__), "..", "Jarfile")
  lock_file = File.join(File.dirname(__FILE__), "..", "Jarfile.lock")
  current_dir = Dir.pwd
  Dir.chdir(File.dirname(lock_file))
  LockJar.lock(jar_file)
  LockJar.install(lock_file)
  LockJar.load(lock_file)
  Dir.chdir(current_dir)

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
