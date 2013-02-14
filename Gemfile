source 'https://rubygems.org'

# Specify your gem's dependencies in diametric.gemspec
gemspec

gem 'rake'

group :development, :test do
  gem 'rspec'
  gem 'pry'
end

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end

platform :mri do
  gem 'yard', :group => :development
  gem 'redcarpet', :group => :development
end

platform :jruby do
  gem 'lock_jar'
  gem 'jruby-openssl'
end
