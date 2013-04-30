require 'conf_helper'

class Somebody
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :parent, Ref, :cardinality => :one
end

describe "RailsConf 2013", :jruby => true do
  context Somebody do
    before(:all) do
      datomic_uri = "datomic:mem://somebody-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @conn.release
    end

    it "should create schema" do
      binding.pry
      Sombody.create_schema(@conn)
    end

    it "should create instances" do
      alice = Somebody.new
      alice.name = "Alice Wonderland"
      alice.parent = ""
      yoko.save
      binding.pry

      clinton = Developer.new(:name => "Clinton N. Dreisbach", :friends => [yoko])
      clinton.save
      binding.pry

      ryan = Developer.new(:name => "Ryan Neufeld", :friends => [clinton, yoko])
      ryan.save
      binding.pry
    end
  end
end
