# -*- ruby -*-
# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diametric/version'

Gem::Specification.new do |gem|
  gem.name          = "diametric"
  gem.version       = Diametric::VERSION
  gem.authors       = ["Clinton N. Dreisbach", "Ryan K. Neufeld", "Yoko Harada"]
  gem.license       = 'MIT'
  gem.email         = ["crnixon@gmail.com", "ryan@thinkrelevance.com", "yoko@thinkrelevance.com"]
  gem.summary       = %q{ActiveModel for Datomic}
  gem.description   = <<EOF
Diametric is a library for building schemas, queries, and transactions
for Datomic from Ruby objects. It is also used to map Ruby objects
as entities into a Datomic database.
EOF
  gem.homepage      = "https://github.com/relevance/diametric"

  gem.files         = %w(Gemfile Jarfile LICENSE.txt README.md Rakefile datomic_version.yml diametric.gemspec) + Dir.glob('lib/**/*') + Dir.glob('ext/**/*') + Dir.glob('spec/**/*')
  gem.executables   = []
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.require_paths = ["lib"]
  gem.executables = ["datomic-rest", "download-datomic"]

  gem.add_dependency 'edn', '~> 1.0', '>= 1.0.2'
  gem.add_dependency 'activesupport', '>= 3.2.16'
  gem.add_dependency 'activemodel', '>= 3.2.16'
  gem.add_dependency 'datomic-client', '~> 0.4', '>= 0.4.1'
  gem.add_dependency 'rubyzip', '~> 0.9', '>= 0.9.9'
  gem.add_dependency 'uuid', '~> 2.3', '>= 2.3.7'
  gem.add_development_dependency 'rspec', '~> 2.3', '>= 2.14.1'

  gem.extensions = ['Rakefile']
end
