require 'spec_helper'
require 'diametric/entity'
require 'datomic/client'

# Datomic's `rest` needs to run for these tests to pass:
#   bin/rest 9000 test datomic:mem://

describe Diametric::Entity, :integration => true, :jruby => true do
  context Penguin do
    before(:all) do
      @datomic_uri = ENV['DATOMIC_URI'] || 'datomic:mem://animals'
      @conn = Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
      Penguin.create_schema(@conn)
    end

    after(:all) do
      @conn.release
    end

    let(:query) { Diametric::Query.new(Penguin, @conn, true) }
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

  context Choice do
    before(:all) do
      @datomic_uri = ENV['DATOMIC_URI'] || 'datomic:mem://choices'
      @conn2 = Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
      Choice.create_schema(@conn2)
    end

    after(:all) do
      @conn2.release
    end

    it "should save entity" do
      choice = Choice.new(:item => "Boots", :checked => true)
      choice.save.should_not be_nil
      result = Diametric::Persistence::Peer.q("[:find ?e :in $ :where [?e :choice/checked]]", @conn2.db)
      choice = Choice.from_dbid_or_entity(result.first.first, @conn2.db)
      choice.checked.should be_true
    end
  end

  context Customer do
    before(:all) do
      @datomic_uri = ENV['DATOMIC_URI'] || 'datomic:mem://choices'
      @conn3 = Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
      Customer.create_schema(@conn3)
    end

    after(:all) do
      @conn3.release
    end

    it "should save entity with Diametric uuid" do
      id = Diametric::Persistence::Peer.squuid
      customer = Customer.new(:name => "John Smith", :id => id)
      customer.save.should_not be_nil
      result = Diametric::Persistence::Peer.q("[:find ?e :in $ :where [?e :customer/name]]", @conn3.db)
      customer2 = Customer.from_dbid_or_entity(result.first.first, @conn3.db)
      customer2.name.should == "John Smith"
      customer2.id.to_s.should == id.to_s
    end

    it "should save entity with Ruby uuid" do
      require 'uuid'
      id = UUID.new.generate
      customer = Customer.new(:name => "Wilber Hoe", :id => id)
      customer.save.should_not be_nil
      result = Diametric::Persistence::Peer.q("[:find ?e :in $ [?name] :where [?e :customer/name ?name]]", @conn3.db, ["Wilber Hoe"])
      customer2 = Customer.from_dbid_or_entity(result.first.first, @conn3.db)
      customer2.name.should == "Wilber Hoe"
      customer2.id.to_s.should == id.to_s
    end
  end

end
