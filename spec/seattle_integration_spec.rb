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
      Seattle.create_schema(@u_conn).get
      filename = File.join(File.dirname(__FILE__), "data", "seattle-data0.dtm")
      list = Diametric::Persistence::Utils.read_all(filename)
      map = @u_conn.transact(list.first).get
      map.should_not be_nil
    end
  end

  context Seattle do
    before(:all) do
      datomic_uri = "datomic:mem://seattle-#{SecureRandom.uuid}"
      @s_conn1 = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@s_conn1).get
      District.create_schema(@s_conn1).get
      Seattle.create_schema(@s_conn1).get
      filename = File.join(File.dirname(__FILE__), "data", "seattle-data0.dtm")
      list = Diametric::Persistence::Utils.read_all(filename)
      map = @s_conn1.transact(list.first).get
    end

    after(:all) do
      @s_conn1.release
    end

    it "should get all community names" do
      query = Diametric::Query.new(Seattle, @s_conn1)
      results = query.all
      results.size.should == 362
    end
  end
end
