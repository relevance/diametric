source 'https://rubygems.org'

# Specify your gem's dependencies in diametric.gemspec
gemspec

# Development-only dependencies
gem 'rake'
gem 'rspec'
gem 'pry'

platform :mri do
  gem 'yard', :group => :development
  gem 'redcarpet', :group => :development
end

platform :jruby do
  gem 'jruby-openssl'
  gem 'lock_jar'
end
