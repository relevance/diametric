require 'spec_helper'
require 'diametric/entity'
require 'datomic/client'

describe Diametric::Entity, :integration => true, :jruby => true do
  context District do
    before(:all) do
      datomic_uri = "datomic:mem://district-#{SecureRandom.uuid}"
      @connection = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @connection.release
    end
    let(:district) { District.create_schema }
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
      @connection = Diametric::Persistence::Peer.connect(datomic_uri)
      District.create_schema.get
    end
    after(:all) do
      @connection.release
    end
    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      district.save.should_not be_nil
    end
    it "should get instance" do
      query = Diametric::Query.new(District)
      district = query.where(:name => "East").first
      district.name.should == "East"
      district.region.should == District::Region::E
    end
  end
end
