require 'rspec'
require 'diametric'

RSpec.configure do |c|
  c.fail_fast = true
  unless ENV['INTEGRATION']
    c.filter_run_excluding :integration => true
  end
  c.filter_run_including :focused => true
  c.alias_example_to :fit, :focused => true
  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

class Person
  include Diametric::Data

  attr :name, String, :index => true
  attr :email, String, :cardinality => :many
  attr :birthday, DateTime
  attr :awesome, :boolean, :doc => "Is this person awesome?"
  attr :ssn, String, :unique => :value
  attr :secret_name, String, :unique => :identity
  attr :bio, String, :fulltext => true
end

class Goat
  include Diametric::Data

  attr :name, String
  attr :birthday, DateTime
end
