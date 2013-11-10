require 'conf_helper'

class Somebody
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :mom, Ref, :cardinality => :one
  attribute :dad, Ref, :cardinality => :one
  attribute :kids, Ref, :cardinality => :many
end

describe "RailsConf 2013", :jruby => true do
  context Somebody do
    before(:all) do
      datomic_uri = "datomic:mem://somebody-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Somebody.create_schema(@conn).get
    end

    after(:all) do
      @conn.release
    end

    it "should create instances" do
      mom = Somebody.new(name: "Snow White")
      mom.save(@conn)
      dad = Somebody.new(name: "Prince Brave")
      dad.save(@conn)
      binding.pry
      Somebody.new(name: "Alice Wonderland", mom: mom, dad: dad).save(@conn)
      binding.pry
      me = Diametric::Query.new(Somebody, @conn, true).where(name: "Alice Wonderland").first
      binding.pry
      puts "me: #{me.name}, me's mom: #{me.mom.name}, me's dad: #{me.dad.name}"
      mario = Somebody.new(name: "Mario", mom: me)
      mario.save
      luigi = Somebody.new(name: "Luigi", mom: me)
      luigi.save
      me.update_attributes(kids: [mario, luigi])
      me = Diametric::Query.new(Somebody, @conn, true).where(name: "Alice Wonderland").first
      puts me.kids.inspect
      binding.pry
      puts Somebody.reify(me.kids.first.mom).name
    end
  end
end
