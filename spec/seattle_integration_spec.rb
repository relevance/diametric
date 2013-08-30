require 'spec_helper'
require 'diametric/entity'
require 'datomic/client'

describe "Seattle Sample", :integration => true, :jruby => true do
  context Diametric::Persistence::Utils do
    before(:all) do
      datomic_uri = "datomic:mem://utils-#{SecureRandom.uuid}"
      @u_conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after(:all) do
      @u_conn.release
    end

    it "should read all data from filename" do
      filename = File.join(File.dirname(__FILE__), "data", "seattle-data0.dtm")
      list = Diametric::Persistence::Utils.read_all(filename)
      list.first.size.should == 450
    end

    it "should transact data read from file" do
      Neighborhood.create_schema(@u_conn).get
      District.create_schema(@u_conn).get
      Community.create_schema(@u_conn).get
      filename = File.join(File.dirname(__FILE__), "data", "seattle-data0.dtm")
      list = Diametric::Persistence::Utils.read_all(filename)
      map = @u_conn.transact(list.first).get
      map.should_not be_nil
    end
  end

  context Community do
    before(:all) do
      datomic_uri = "datomic:mem://community-#{SecureRandom.uuid}"
      @s_conn1 = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@s_conn1).get
      District.create_schema(@s_conn1).get
      Community.create_schema(@s_conn1).get
      filename = File.join(File.dirname(__FILE__), "data", "seattle-data0.dtm")
      list = Diametric::Persistence::Utils.read_all(filename)
      map = @s_conn1.transact(list.first).get
    end

    after(:all) do
      @s_conn1.release
    end

    it "should get all community names" do
      query = Diametric::Query.new(Community, @s_conn1)
      results = query.all
      results.size.should == 150
    end

    it "should get reverse reference" do
      query = Diametric::Query.new(Neighborhood, @s_conn1, true).where(:name => "Capitol Hill")
      communities = query.first.community_from_this_neighborhood(@s_conn1)
      communities.size.should == 6
      communities.collect(&:name).should =~
        ["15th Ave Community",
         "Capitol Hill Community Council",
         "Capitol Hill Housing",
         "Capitol Hill Triangle",
         "CHS Capitol Hill Seattle Blog",
         "KOMO Communities - Captol Hill"]
    end
  end

  context Community do
    before(:all) do
      datomic_uri = "datomic:mem://community-#{SecureRandom.uuid}"
      @s_conn2 = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@s_conn2).get
      District.create_schema(@s_conn2).get
      Community.create_schema(@s_conn2).get
      filename0 = File.join(File.dirname(__FILE__), "data", "seattle-data0.dtm")
      list = Diametric::Persistence::Utils.read_all(filename0)
      map0 = @s_conn2.transact(list.first).get
    end

    after(:all) do
      @s_conn2.release
    end

    it "should add another set of data" do
      query = Diametric::Query.new(Community, @s_conn2)
      results = query.all
      results.size.should == 150

      past = Time.now

      filename1 = File.join(File.dirname(__FILE__), "data", "seattle-data1.dtm")
      list = Diametric::Persistence::Utils.read_all(filename1)

      map2 = @s_conn2.transact(list.first).get
      query = Diametric::Query.new(Community, @s_conn2)
      results = query.all
      results.size.should == 258

      past_db = @s_conn2.db.as_of(past)
      query = Diametric::Query.new(Community, past_db)
      results = query.all
      results.size.should == 150
    end
  end
end
