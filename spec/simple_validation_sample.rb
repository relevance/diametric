require 'conf_helper'

class Person
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  validates_presence_of :name
  attribute :nerd_rate, Integer
end

describe "RailsConf 2013", :jruby => true do
  context Person do
    before(:all) do
      datomic_uri = "datomic:mem://person-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @conn.release
    end

    it "should create schema and save instaces" do
      binding.pry
      Person.create_schema(@conn).get

      foo = Person.new
      binding.pry
      foo.save
    end
  end
end
