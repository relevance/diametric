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
      district.tx_data.should be_empty
    end
    it "should get instance" do
      query = Diametric::Query.new(District, @d_conn2, true)
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

    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      neighborhood = Neighborhood.new
      neighborhood.name = "Capitol Hill"
      neighborhood.district = district
      neighborhood.save(@n_conn2).should_not be_nil
      district.tx_data.should be_empty
      neighborhood.tx_data.should be_empty
    end

    it "should not include tx_data of saved entity" do
      district = District.new
      district.name = "Southwest"
      district.region = District::Region::SW
      district.save(@n_conn2)
      neighborhood = Neighborhood.new
      neighborhood.name = "Admiral (West Seattle)"
      neighborhood.district = district

      result = []
      neighborhood.parse_tx_data(neighborhood.tx_data, result)
      result.first[:"neighborhood/district"].to_s.should match(/^\d+/)
      neighborhood.save(@n_conn2)
      district.tx_data.should be_empty
      neighborhood.tx_data.should be_empty
    end

    it "should get instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      neighborhood = Neighborhood.new
      neighborhood.name = "Capitol Hill"
      neighborhood.district = district
      neighborhood.save(@n_conn2).should_not be_nil

      query = Diametric::Query.new(Neighborhood, @n_conn2, true)
      neighborhood = query.where(:name => "Capitol Hill").first
      neighborhood.dbid.should_not be_nil
      neighborhood.name.should == "Capitol Hill"
      neighborhood.district.should be_a(District)
      neighborhood.district.dbid.should_not be_nil
      neighborhood.district.name.should == "East"
      neighborhood.district.region.should == District::Region::E
    end

    it "should not resolve ref type dbid" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      neighborhood = Neighborhood.new
      neighborhood.name = "Capitol Hill"
      neighborhood.district = district
      neighborhood.save(@n_conn2).should_not be_nil

      query = Diametric::Query.new(Neighborhood, @n_conn2, true)
      neighborhood = query.where(:name => "Capitol Hill").first
      neighborhood.name.should == "Capitol Hill"
      neighborhood.district.should be_a(District)
    end
  end

  context Community do
    before(:all) do
      datomic_uri = "datomic:mem://community-#{SecureRandom.uuid}"
      @s_conn1 = Diametric::Persistence::Peer.connect(datomic_uri)
    end
    after(:all) do
      @s_conn1.release
    end
    it "should create schema" do
      Community.create_schema(@s_conn1).get.should_not be_nil
    end
  end

  context Community do
    before(:all) do
      datomic_uri = "datomic:mem://community-#{SecureRandom.uuid}"
      @s_conn2 = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@s_conn2).get
      District.create_schema(@s_conn2).get
      Community.create_schema(@s_conn2).get
    end
    after(:all) do
      @s_conn2.release
    end

    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      neighborhood = Neighborhood.new
      neighborhood.name = "Capitol Hill"
      neighborhood.district = district
      community = Community.new
      community.name = "15th Ave Community"
      community.url = "http://groups.yahoo.com/group/15thAve_Community/"
      community.neighborhood = neighborhood
      community.category = ["15th avenue residents"]
      community.orgtype = Community::Orgtype::COMMUNITY
      community.type = Community::Type::EMAIL_LIST
      community.save(@n_conn2).should_not be_nil
    end

    it "should get instance" do
      query = Diametric::Query.new(Community, @s_conn2, true)
      community = query.where(:name => "15th Ave Community").first
      community.dbid.should_not be_nil
      community.name.should == "15th Ave Community"
      community.url.should == "http://groups.yahoo.com/group/15thAve_Community/"
      community.neighborhood.should be_a(Neighborhood)
      community.neighborhood.dbid.should_not be_nil
      community.neighborhood.name.should == "Capitol Hill"
      community.neighborhood.district.should be_a(District)
      community.neighborhood.district.dbid.should_not be_nil
      community.neighborhood.district.name.should == "East"
      community.neighborhood.district.region.should == District::Region::E
      community.category == ["15th avenue residents"]
      community.orgtype.should == Community::Orgtype::COMMUNITY
      community.type.should == Community::Type::EMAIL_LIST
    end
  end

end
