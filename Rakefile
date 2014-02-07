# -*- ruby -*-
begin
  require 'rake'
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
require 'rspec'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)


# setting for rake compiler
if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  require 'lock_jar'
  LockJar.lock
  locked_jars = LockJar.load

  require 'rake/javaextensiontask'
  Rake::JavaExtensionTask.new('diametric') do |ext|
    jruby_home = ENV['MY_RUBY_HOME'] # this is available of rvm
    jars = ["#{jruby_home}/lib/jruby.jar"] + FileList['lib/*.jar'] + locked_jars
    ext.classpath = jars.map {|x| File.expand_path x}.join ':'
    ext.name = 'diametric_service'
  end
end