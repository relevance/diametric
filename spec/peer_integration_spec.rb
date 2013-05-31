require 'spec_helper'
require 'diametric/entity'
require 'datomic/client'

# Datomic's `rest` needs to run for these tests to pass:
#   bin/rest 9000 test datomic:mem://

describe Diametric::Entity, :integration => true, :jruby => true do
  before(:all) do
    @datomic_uri = ENV['DATOMIC_URI'] || 'datomic:mem://animals'
    @conn = Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
    Penguin.create_schema(@conn)
  end

  let(:query) { Diametric::Query.new(Penguin, @conn) }
  it "should update entity" do
    penguin = Penguin.new(:name => "Mary", :age => 2)
    penguin.save(@conn)
    penguin.update(:age => 3)
    penguin.name.should == "Mary"
    penguin.age.should == 3
  end

  it "should search upadated attributes" do
    penguin = query.where(:name => "Mary").first
    penguin.name.should == "Mary"
    penguin.age.should == 3
  end

  it "should destroy entity" do
    penguin = Penguin.new(:name => "Mary", :age => 2)
    penguin.save(@conn)
    number_of_penguins = Penguin.all.size
    number_of_penguins.should >= 1
    penguin.destroy
    Penguin.all.size.should == (number_of_penguins -1)
  end
end
