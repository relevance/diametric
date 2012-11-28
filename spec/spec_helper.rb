require 'rspec'
require 'pry'
require 'diametric'
Dir["./spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |c|
#  c.fail_fast = true

  c.filter_run_excluding :integration => true unless ENV['INTEGRATION']
  c.filter_run_excluding :jruby => true unless RUBY_ENGINE == "jruby"

  c.filter_run_including :focused => true
  c.alias_example_to :fit, :focused => true

  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

shared_examples "ActiveModel" do |model|
  require 'test/unit/assertions'
  require 'active_model/lint'
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  active_model_lints = ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/)

  let(:model) { subject }

  active_model_lints.each do |test_name|
    it "#{test_name.sub(/^test_/, '')}" do
      send(test_name)
    end
  end
end

class Person
  include Diametric::Entity

  attribute :name, String, :index => true
  attribute :email, String, :cardinality => :many
  attribute :birthday, DateTime
  attribute :awesome, :boolean, :doc => "Is this person awesome?"
  attribute :ssn, String, :unique => :value
  attribute :secret_name, String, :unique => :identity
  attribute :bio, String, :fulltext => true
  attribute :middle_name, String, :default => "Danger"
  attribute :nicknames, String, :cardinality => :many, :default => ["Buddy", "Pal"]
  attribute :parent, Ref, :cardinality => :many, :doc => "A person's parent"
end

class Goat
  include Diametric::Entity

  attribute :name, String
  attribute :birthday, DateTime
end

require 'diametric/persistence/rest'
class Robin
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String
  attribute :age, Integer
end

if RUBY_ENGINE == "jruby"
  require 'diametric/persistence/peer'
  class Penguin
    include Diametric::Entity
    include Diametric::Persistence::Peer

    attribute :name, String
    attribute :age, Integer
  end
end