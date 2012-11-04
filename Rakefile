begin
  require "bundler/gem_tasks"
  require 'rspec/core/rake_task'
rescue LoadError
end


task :default => :prepare

task :prepare => :install_lockjar do
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    require 'lock_jar'

    # get jarfile relative the gem dir
    lockfile = File.expand_path("../Jarfile.lock", __FILE__)

    LockJar.install(lockfile)
  end
end

task :install_lockjar do
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    require 'rubygems'
    require 'rubygems/dependency_installer'
    inst = Gem::DependencyInstaller.new
    inst.install 'lock_jar', '~> 0.7.2'
  end
end

desc "Run all RSpec tests"
RSpec::Core::RakeTask.new(:spec)
