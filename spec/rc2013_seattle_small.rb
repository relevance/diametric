require 'sample_helper'
require 'support/entities'
require 'pry'

describe Diametric::Entity, :jruby => true do
  context Community do
    before(:all) do
      datomic_uri = "datomic:mem://community-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Neighborhood.create_schema(@conn).get
      District.create_schema(@conn).get
      Community.create_schema(@conn).get
      binding.pry
    end
    after(:all) do
      @conn.release
    end

    it "should save instance" do
      district = District.new
      district.name = "East"
      district.region = District::Region::E
      binding.pry
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
      binding.pry
      res = community.save(@conn)
      binding.pry

      query = Diametric::Query.new(Community, @conn, true)
      community = query.where(:name => "15th Ave Community").first
      binding.pry
      puts "community.name: #{community.name}"
      puts "community.url: #{community.url}"
      puts "community.category: #{community.category}"
      puts "community.category: #{community.category.to_a.join(",")}"
      puts "community.orgtype: #{community.orgtype}"
      puts "community.orgtype == Community::Orgtype::COMMUNITY ? #{community.orgtype == Community::Orgtype::COMMUNITY}"
      puts "community.type: #{community.type}"
      puts "community.type == Community::Type::EMAIL_LIST ? #{community.type == Community::Type::EMAIL_LIST}"
      binding.pry
      puts "community.neighborhood.dbid: #{community.neighborhood.dbid}"        
      puts "community.neighborhood.name: #{community.neighborhood.name}"
      binding.pry
      puts "community.neighborhood.district.dbid: #{community.neighborhood.district.dbid}"
      puts "community.neighborhood.district.name: #{community.neighborhood.district.name}"
      puts "community.neighborhood.district.region: #{community.neighborhood.district.region}"
      puts "community.neighborhood.district.region == District::Region::E ? #{community.neighborhood.district.region == District::Region::E}"
      binding.pry
    end
  end

end
