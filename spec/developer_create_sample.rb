require 'conf_helper'

class Developer
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :friends, Ref, :cardinality => :many
end

describe "RailsConf 2013", :jruby => true do
  context Developer do
    before(:all) do
      datomic_uri = "datomic:mem://developer-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @conn.release
    end

    it "should create schema and save instaces" do
      binding.pry
      Developer.create_schema(@conn)

      yoko = Developer.new
      yoko.name = "Yoko Harada"
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
