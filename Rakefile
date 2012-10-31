begin
  require "bundler/gem_tasks"
rescue LoadError
end

task :default => :prepare

task :prepare do
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    require 'lock_jar'

    # get jarfile relative the gem dir
    lockfile = File.expand_path("../Jarfile.lock", __FILE__)

    LockJar.install(lockfile)
  end
end
