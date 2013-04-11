require 'spec_helper'
require 'diametric/entity'
require 'datomic/client'

describe Diametric::Entity, :integration => true, :jruby => true do
  context District do
    before(:all) do
      datomic_uri = "datomic:mem://district-#{SecureRandom.uuid}"
      @d_conn1 = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @d_conn1.release
    end
    let(:district) { District.create_schema(@d_conn1) }
    it "should create schema" do
      district.should_not be_nil
    end
    it "should return future object" do
      district.should be_a(Diametric::Persistence::ListenableFuture)
    end
    it "should return object by get from future do" do
      district.get.should_not be_nil
    end
  end

  context District do
    before(:all) do
      datomic_uri = "datomic:mem://district-#{SecureRandom.uuid}"
      @d_conn2 = Diametric::Persistence::Peer.connect(datomic_uri)
      District.create_schema(@d_conn2).get
    end
    after(:all) do
      @d_conn2.release
    end
    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      district.save(@d_conn2).should_not be_nil
    end
    it "should get instance" do
      query = Diametric::Query.new(District, @d_conn2)
      district = query.where(:name => "East").first
      district.name.should == "East"
      district.region.should == District::Region::E
    end
  end

  context Neighborhood do
    before(:all) do
      datomic_uri = "datomic:mem://neighborhood-#{SecureRandom.uuid}"
      @n_conn1 = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @n_conn1.release
    end
    it "should create schema" do
      Neighborhood.create_schema(@n_conn1).get.should_not be_nil
    end
  end

  context Neighborhood do
    before(:all) do
      datomic_uri = "datomic:mem://neighborhood-#{SecureRandom.uuid}"
      @n_conn2 = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@n_conn2).get
      District.create_schema(@n_conn2).get
    end
    after(:all) do

      @n_conn2.release
    end

    #it "should save instance", :focused=>true do
    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
          neighborhood = Neighborhood.new
      neighborhood.name = "Capitol Hill"
      neighborhood.district = district
      neighborhood.save(@n_conn2).should_not be_nil
    end

    #it "should get instance", :focused=>true do
    it "should get instance" do
      query = Diametric::Query.new(Neighborhood, @n_conn2)
      neighborhood = query.where(:name => "Capitol Hill").first
      neighborhood.name.should == "Capitol Hill"
      neighborhood.district.name.should == "East"
      neighborhood.district.region.should == District::Region::E
    end

  end
end
