# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diametric/version'

Gem::Specification.new do |gem|
  gem.name          = "diametric"
  gem.version       = Diametric::VERSION
  gem.authors       = ["Clinton N. Dreisbach", "Ryan K. Neufeld", "Yoko Harada"]
  gem.email         = ["crnixon@gmail.com", "ryan@thinkrelevance.com", "yoko@thinkrelevance.com"]
  gem.summary       = %q{ActiveModel for Datomic}
  gem.description   = <<EOF
Diametric is a library for building schemas, queries, and transactions
for Datomic from Ruby objects. It is also used to map Ruby objects
as entities into a Datomic database.
EOF
  gem.homepage      = "https://github.com/relevance/diametric"

  gem.files         = %w(Gemfile Jarfile Jarfile.lock LICENSE.txt README.md Rakefile diametric.gemspec) + Dir.glob('lib/**/*')
  gem.executables   = []
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.require_paths = ["lib"]

  gem.add_dependency 'edn', '~> 1.0'
  gem.add_dependency 'activesupport', '>= 3.0.0'
  gem.add_dependency 'activemodel', '>= 3.0.0'
  gem.add_dependency 'datomic-client', '~> 0.4.1'
  gem.add_dependency 'rspec', '~> 2.12.0'
  gem.add_dependency 'lock_jar', '= 0.7.2' if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  gem.add_dependency 'jruby-openssl', '~> 0.8.2' if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"

  gem.add_development_dependency 'pry', '~> 0.9.12'
  gem.add_development_dependency 'guard', '~> 1.6.2'
  gem.add_development_dependency 'guard-rspec', '~> 2.4.0'
  gem.add_development_dependency 'rb-inotify', '~> 0.9.0'
  gem.add_development_dependency 'rb-fsevent', '~> 0.9.3'
  gem.add_development_dependency 'rb-fchange', '~> 0.0.6'
  gem.add_development_dependency 'yard', '~> 0.8.4.1' if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
  gem.add_development_dependency 'redcarpet', '~> 2.2.2' if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"

  gem.extensions = ['Rakefile']
end
