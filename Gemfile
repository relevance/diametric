source 'https://rubygems.org'

# Specify your gem's dependencies in diametric.gemspec
gemspec

# Development-only dependencies
gem 'rake'
gem 'rspec'
gem 'pry'

gem 'guard'
gem 'guard-rspec'
gem 'rb-inotify', :require => false
gem 'rb-fsevent', :require => false
gem 'rb-fchange', :require => false

platform :mri do
  gem 'yard', :group => :development
  gem 'redcarpet', :group => :development
end

platform :jruby do
  gem 'jruby-openssl'
  gem 'lock_jar'
end
