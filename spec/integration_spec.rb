require 'spec_helper'
require 'datomic/client'

# Datomic's `rest` needs to run for these tests to pass:
#   bin/rest 9000 test datomic:mem://

describe Diametric, :integration => true do
  before(:all) do
    @datomic_uri = ENV['DATOMIC_URI'] || 'http://localhost:9000'
    @storage = ENV['DATOMIC_STORAGE'] || 'test'
    @dbname = ENV['DATOMIC_NAME'] || "test-#{Time.now.to_i}"
    @client = Datomic::Client.new @datomic_uri, @storage
    @client.create_database(@dbname)
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

end
