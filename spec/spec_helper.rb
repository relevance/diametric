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

  attribute :name, String, :index => true
  attribute :email, String, :cardinality => :many
  attribute :birthday, DateTime
  attribute :awesome, :boolean, :doc => "Is this person awesome?"
  attribute :ssn, String, :unique => :value
  attribute :secret_name, String, :unique => :identity
  attribute :bio, String, :fulltext => true
end

class Goat
  include Diametric::Data

  attribute :name, String
  attribute :birthday, DateTime
end
