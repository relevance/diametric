require 'spec_helper'
require 'datomic/client'

# Datomic's `rest` needs to run for these tests to pass:
#   bin/rest 9000 test datomic:mem://

describe Diametric::Entity, :integration => true do
  before(:all) do
    @datomic_uri = ENV['DATOMIC_URI'] || 'datomic:mem://animals'
    Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
    Penguin.create_schema
  end

  let(:query) { Diametric::Query.new(Penguin) }
  it "should update" do
    penguin = Penguin.new(:name => "Mary", :age => 2)
    penguin.save
    penguin.update(:age => 3)
    penguin.name.should == "Mary"
    penguin.age.should == 3
  end

  it "should search upadated attributes" do
    penguin = query.where(:name => "Mary").first
    penguin.name.should == "Mary"
    penguin.age.should == 3
  end

  it "should"
end
