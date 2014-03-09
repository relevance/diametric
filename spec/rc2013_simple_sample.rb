require 'sample_helper'
require 'pry'

class Person
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :nerd_rate, Integer
end

describe "RailsConf 2013", :jruby => true do
  context Person do
    before(:all) do
      datomic_uri = "datomic:mem://person-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      binding.pry
    end
    after(:all) do
      @conn.release
    end

    it "should create schema and save instaces" do
      binding.pry
      Person.create_schema(@conn).get

      foo = Person.new
      foo.name = "Yoko"
      foo.nerd_rate = 50
      binding.pry
      foo.save

      bar = Person.new(:name => "Clinton", :nerd_rate => 98)
      binding.pry
      bar.save

      query = Diametric::Query.new(Person, @conn.db, true)
      result = query.all
      binding.pry

      query = Diametric::Query.new(Person, @conn.db, true).where(:name => "Yoko")
      result = query.all
      binding.pry

      past = Time.now
      binding.pry

      yoko = result.first
      yoko.update_attributes(:nerd_rate => 70)
      binding.pry

      query = Diametric::Query.new(Person, @conn.db, true).where(:name => "Yoko")
      result = query.all
      binding.pry

      past_db = @conn.db.as_of(past)
      binding.pry

      query = Diametric::Query.new(Person, past_db, true).where(:name => "Yoko")
      result = query.all
      binding.pry
      
      query = Diametric::Query.new(Person, @conn.db, true).filter(:>, :nerd_rate, 60)
      result = query.all
      binding.pry

      query = Diametric::Query.new(Person, past_db, true).filter(:>, :nerd_rate, 60)
      result = query.all
      binding.pry

    end
  end
end
