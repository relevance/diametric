require 'spec_helper'
require 'datomic/client'

# Datomic's `rest` needs to run for these tests to pass:
#   bin/rest 9000 test datomic:mem://

describe Diametric::Entity, :integration => true do
  before(:all) do
    @datomic_uri = ENV['DATOMIC_URI'] || 'http://localhost:9000'
    @storage = ENV['DATOMIC_STORAGE'] || 'free'
    @dbname = ENV['DATOMIC_NAME'] || "test-#{Time.now.to_i}"
    @client = Datomic::Client.new @datomic_uri, @storage
    @client.create_database(@dbname)
    sleep 0.5
  end

  it "can load the schema" do
    resp = @client.transact(@dbname, Person.schema)
    resp.code.should == 201
    resp.data.should be_a(Hash)
    resp.data.keys.sort.should == [:"db-after", :"db-before", :tempids, :"tx-data"]
  end

  describe "with a schema" do
    before(:all) do
      @client.transact(@dbname, Person.schema)
      @client.transact(@dbname, Goat.schema)
    end

    it "can transact an entity" do
      birthday = DateTime.parse("1976-09-04")
      goat = Goat.new(:name => "Beans", :birthday => birthday)
      resp = @client.transact(@dbname, goat.tx_data)
      resp.code.should == 201
      resp.data.should be_a(Hash)
      resp.data.keys.sort.should == [:"db-after", :"db-before", :tempids, :"tx-data"]
    end
  end

  describe "with an entity" do
    before(:all) do
      goat = Goat.new(:name => "Josef", :birthday => DateTime.parse("1976-09-04"))
      @client.transact(@dbname, goat.tx_data)
    end

    it "can query for that entity" do
      query, args = Diametric::Query.new(Goat).where(:name => "Josef").data
      args = args.unshift({:"db/alias" => "#{@storage}/#{@dbname}"})
      resp = @client.query(query, args)
      resp.code.should == 200
      resp.data.should be_a(Array)
      resp.data.count.should == 1
      resp.data.first.count.should == 3
    end

    it "can rehydrate an entity from a query" do
      query, args = Diametric::Query.new(Goat).where(:name => "Josef").data
      args = args.unshift({:"db/alias" => "#{@storage}/#{@dbname}"})
      resp = @client.query(query, args)
      resp.code.should == 200

      goats = resp.data.map { |data| Goat.from_query(data) }
      goats.first.name.should == "Josef"
    end
  end

  describe "with persistence module" do
    before(:all) do
      Robin.create_schema
    end

    let(:query) { Diametric::Query.new(Robin) }
    it "can create entity" do
      robin = Robin.new
      
      expect { robin.save! }.to raise_error(Diametric::Errors::ValidationError)
      robin.save.should be_false
      robin.name = "Mary"
      robin.age = 3
      expect { robin.save! }.to_not raise_error(Diametric::Errors::ValidationError)
      robin.persisted?.should be_true
    end
    it "can update entity" do
      robin = Robin.new(:name => "Mary", :age => 2)
      robin.save
      robin.update(:age => 3)
      robin.name.should == "Mary"
      robin.age.should == 3
    end
    it "should search upadated attributes" do
      robin = query.where(:name => "Mary").first
      robin.name.should == "Mary"
      robin.age.should == 3
    end
    it "can destroy entity" do
      robin = Robin.new(:name => "Mary", :age => 2)
      robin.save
      number_of_robins = Robin.all.size
      number_of_robins.should >= 1
      robin.destroy
      Robin.all.size.should == (number_of_robins -1)
    end
  end

end
