require 'spec_helper'

class Developer
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :nerd_rate, Integer
  attribute :friends, Ref, :cardinality => :many
end

describe Developer, :jruby => true do
  before do
    datomic_uri = "datomic:mem://developer-#{SecureRandom.uuid}"
    @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    Developer.create_schema(@conn)
  end
  after do
    @conn.release
  end

  it "should save an instace and get it" do
    yoko = Developer.new
    yoko.name = "Yoko Harada"
    yoko.save(@conn)
    query = Diametric::Query.new(Developer, @conn, true)
    result = query.all
    result.size.should == 1
    result.first.name.should == "Yoko Harada"
  end

  it "should make query with the argument" do
    yoko = Developer.new
    yoko.name = "Yoko Harada"
    yoko.nerd_rate = 50
    yoko.save(@conn)
    query = Diametric::Query.new(Developer, @conn, true).where(:name => "Yoko Harada")
    query_data = "[:find ?e :in $ [?name] :where [?e :developer/name ?name]]"
    query.data.first.to_edn.gsub(" ", "").should == query_data.gsub(" ", "")
    result = query.all
    result.size.should == 1
    result.first.nerd_rate.should == 50
  end

  it "should not resolve referenced object" do
    yoko = Developer.new
    yoko.name = "Yoko Harada"
    yoko.nerd_rate = 50
    yoko.save(@conn)
    clinton = Developer.new(:name => "Clinton N. Dreisbach", :friends => [yoko])
    clinton.nerd_rate = 98
    clinton.save(@conn)

    query = Diametric::Query.new(Developer, @conn).where(:name => "Clinton N. Dreisbach")
    result = query.all
    result.size.should == 1

    developer = Developer.reify(result.first.first, @conn.db, false)
    friends = developer.friends
    friends.size.should == 1
    friends.first.should be_a(Diametric::Persistence::Entity)
  end

  it "should find three developers" do
    yoko = Developer.new
    yoko.name = "Yoko Harada"
    yoko.nerd_rate = 50
    yoko.save(@conn)
    clinton = Developer.new(:name => "Clinton N. Dreisbach", :friends => [yoko])
    clinton.nerd_rate = 98
    clinton.save(@conn)
    ryan = Developer.new(:name => "Ryan Neufeld", :friends => [clinton, yoko])
    ryan.nerd_rate = 80
    ryan.save(@conn)

    query = Diametric::Query.new(Developer, @conn)
    result = query.all
    result.size.should == 3
    resolved_result = result.map {|m| Developer.reify(m.first, @conn)}
    resolved_result.collect(&:nerd_rate).should =~ [50, 98, 80]
  end

  it "should filter out developers" do
    yoko = Developer.new
    yoko.name = "Yoko Harada"
    yoko.nerd_rate = 50
    yoko.save(@conn)
    clinton = Developer.new(:name => "Clinton N. Dreisbach", :friends => [yoko])
    clinton.nerd_rate = 98
    clinton.save(@conn)
    ryan = Developer.new(:name => "Ryan Neufeld", :friends => [clinton, yoko])
    ryan.nerd_rate = 80
    ryan.save(@conn)

    query = Diametric::Query.new(Developer, @conn).filter(:>, :nerd_rate, 70)
    query_data = "[:find ?e :in $ [?nerd_ratevalue] :where [?e :developer/nerd_rate ?nerd_rate] [(> ?nerd_rate ?nerd_ratevalue)]]"
    query.data.first.to_edn.gsub(" ", "").should == query_data.gsub(" ", "")
    result = query.all
    result.size.should == 2
  end

  it "should resolve referenced objects" do
    yoko = Developer.new
    yoko.name = "Yoko Harada"
    yoko.nerd_rate = 50
    yoko.save(@conn)
    clinton = Developer.new(:name => "Clinton N. Dreisbach", :friends => [yoko])
    clinton.nerd_rate = 98
    clinton.save(@conn)
    ryan = Developer.new(:name => "Ryan Neufeld", :friends => [clinton, yoko])
    ryan.nerd_rate = 80
    ryan.save(@conn)

    query = Diametric::Query.new(Developer, @conn, true).where(:name => "Ryan Neufeld")
    result = query.all
    result.size.should == 1
    result.first.friends.collect(&:name).should =~ ["Yoko Harada", "Clinton N. Dreisbach"]
  end

  it "should not think found objects are dirty" do
    david = Developer.new
    david.name = "David Bock"
    david.nerd_rate = 42
    david.save(@conn)
    query = Diametric::Query.new(Developer, @conn)
    result = query.all
    developer = Developer.reify(result.first.first, @conn.db, false)
    developer.changed.should == []
  end

end
