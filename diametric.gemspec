# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diametric/version'

Gem::Specification.new do |gem|
  gem.name          = "diametric"
  gem.version       = Diametric::VERSION
  gem.authors       = ["Clinton N. Dreisbach"]
  gem.email         = ["crnixon@gmail.com"]
  gem.summary       = %q{ActiveModel for Datomic}
  gem.description   = <<EOF
Diametric is a library for building schemas, queries, and transactions
for Datomic from Ruby objects. It is also used to map Ruby objects
as entities into a Datomic database.
EOF
  gem.homepage      = "https://github.com/crnixon/diametric"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'edn', '~> 1.0'
  gem.add_dependency 'activesupport', '>= 3.0.0'
  gem.add_dependency 'activemodel', '>= 3.0.0'
  gem.add_dependency 'datomic-client', '~> 0.4.1'
  gem.add_dependency 'lock_jar', '~> 0.7.2'

  gem.extensions = ['Rakefile']
end
