require 'conf_helper'
require 'support/entities'

describe Diametric::Entity, :jruby => true do
  context Seattle do
    before(:all) do
      datomic_uri = "datomic:mem://seattle-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@conn).get
      District.create_schema(@conn).get
      Seattle.create_schema(@conn).get
    end
    after(:all) do
      @conn.release
    end

    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      neighborhood = Neighborhood.new
      neighborhood.name = "Capitol Hill"
      neighborhood.district = district
      seattle = Seattle.new
      seattle.name = "15th Ave Community"
      seattle.url = "http://groups.yahoo.com/group/15thAve_Community/"
      seattle.neighborhood = neighborhood
      seattle.category = ["15th avenue residents"]
      seattle.orgtype = Seattle::Orgtype::COMMUNITY
      seattle.type = Seattle::Type::EMAIL_LIST
      binding.pry
      res = seattle.save(@conn)
      binding.pry



      query = Diametric::Query.new(Seattle, @conn, true)
      seattle = query.where(:name => "15th Ave Community").first
      binding.pry
      puts "seattle.name: #{seattle.name}"
      puts "seattle.url: #{seattle.url}"
      puts "seattle.category: #{seattle.category}"
      puts "seattle.category: #{seattle.category.to_a.join(",")}"
      puts "seattle.orgtype: #{seattle.orgtype}"
      puts "seattle.orgtype == Seattle::Orgtype::COMMUNITY ? #{seattle.orgtype == Seattle::Orgtype::COMMUNITY}"
      puts "seattle.type: #{seattle.type}"
      puts "seattle.type == Seattle::Type::EMAIL_LIST ? #{seattle.type == Seattle::Type::EMAIL_LIST}"
      binding.pry
      puts "seattle.neighborhood.dbid: #{seattle.neighborhood.dbid}"        
      puts "seattle.neighborhood.name: #{seattle.neighborhood.name}"
      binding.pry
      puts "seattle.neighborhood.district.dbid: #{seattle.neighborhood.district.dbid}"
      puts "seattle.neighborhood.district.name: #{seattle.neighborhood.district.name}"
      puts "seattle.neighborhood.district.region: #{seattle.neighborhood.district.region}"
      puts "seattle.neighborhood.district.region == District::Region::E ? #{seattle.neighborhood.district.region == District::Region::E}"
      binding.pry
    end
  end

end
