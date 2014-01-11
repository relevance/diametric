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
      bday = DateTime.parse('2005-01-01')
      penguin = Penguin.new(:name => "Mary", :age => 2, :birthday => bday)
      penguin.save(@conn)
      penguin.update(:age => 3)
      penguin.name.should == "Mary"
      penguin.age.should == 3
      penguin.birthday.should == bday
    end

    it "should search upadated attributes" do
      bday = DateTime.parse('1900-02-02')
      penguin = Penguin.new(:name => "Mary J.", :age => 200, :birthday => bday)
      penguin.save(@conn)
      penguin = query.where(:name => "Mary J.").first
      penguin.name.should == "Mary J."
      penguin.age.should == 200
      penguin.birthday == bday
    end

    it "should destroy entity" do
      penguin = Penguin.new(:name => "Mary Jo.", :age => 2)
      penguin.save(@conn)
      number_of_penguins = Penguin.all.size
      number_of_penguins.should >= 1
      penguin.destroy
      Penguin.all.size.should == (number_of_penguins -1)
    end

    it "should find by where query" do
      Penguin.new(name: "Mary Jo.", birthday: DateTime.parse('1900-12-31')).save
      Penguin.new(name: "Mary Jen.", birthday: DateTime.parse('1999-12-31')).save
      Penguin.new(name: "Mary Jr.", birthday: DateTime.parse('2013-01-01')).save
      Penguin.new(name: "Mary Jay.", birthday: DateTime.parse('2011-01-01')).save
      query = Penguin.where(birthday: DateTime.parse('1999-12-31'))
      query.each do |entity|
        entity.birthday.should == DateTime.parse('1999-12-31')
      end
    end

    it "should find by filter query" do
      Penguin.new(name: "Mary Jo.", birthday: DateTime.parse('1890-12-31'), awesomeness: true).save
      Penguin.new(name: "Mary Jen.", birthday: DateTime.parse('1999-12-31'), awesomeness: true).save
      Penguin.new(name: "Mary Jr.", birthday: DateTime.parse('2013-01-01'), awesomeness: false).save
      Penguin.new(name: "Mary Jay.", birthday: DateTime.parse('1850-02-22'), awesomeness: false).save
      query = Penguin.filter(@conn, :<, :birthday, DateTime.parse('1900-01-01'))
      result = query.all
      result.size.should == 2
      result.collect(&:name).should =~ ["Mary Jay.", "Mary Jo."]

      query = Penguin.where(awesomeness: true).filter(:<, :birthday, DateTime.parse('1900-01-01'))
      result = query.all
      result.size.should == 1
      result.first.name.should == "Mary Jo."
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
      choice = Choice.reify(result.first.first, @conn2.db)
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
      customer2 = Customer.reify(result.first.first, @conn3.db)
      customer2.name.should == "John Smith"
      customer2.id.to_s.should == id.to_s
    end

    it "should save entity with Ruby uuid" do
      require 'uuid'
      id = UUID.new.generate
      customer = Customer.new(:name => "Wilber Hoe", :id => id)
      customer.save.should_not be_nil
      result = Diametric::Persistence::Peer.q("[:find ?e :in $ [?name] :where [?e :customer/name ?name]]", @conn3.db, ["Wilber Hoe"])
      customer2 = Customer.reify(result.first.first, @conn3.db)
      customer2.name.should == "Wilber Hoe"
      customer2.id.to_s.should == id.to_s
    end
  end

  context Account do
    before(:all) do
      @datomic_uri = ENV['DATOMIC_URI'] || 'datomic:mem://account'
      @conn4 = Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
      Account.create_schema(@conn4)
    end

    after(:all) do
      @conn4.release
    end

    it "should save entity" do
      account = Account.new(:name => "This month's deposits", :deposit => [100.0, 200.0], :amount => 0.0)
      account.save.should_not be_nil
      result = Diametric::Persistence::Peer.q("[:find ?e :in $ :where [?e :account/name]]", @conn4.db)
      account2 = Customer.reify(result.first.first, @conn4.db)
      account2.name.should == account.name
      account2.amount.should == 0.0
      account2.deposit.should include(100.0)
      account2.deposit.should include(200.0)
    end
  end

  context 'issue43' do
    before do
      @datomic_uri = 'datomic:mem://issue43'
      @conn_issue43 = Diametric::Persistence.establish_base_connection({:uri => @datomic_uri})
      This::Bug.create_schema(@conn_issue43).get
      Outermost::Outer::Inner::Innermost.create_schema(@conn_issue43).get
    end

    after do
      @conn_issue43.release
    end

    it 'should get all entities' do
      This::Bug.new(id: '123').save
      result = This::Bug.all
      result.first.id.should == '123'
    end

    it 'should get all entities of nested modules' do
      Outermost::Outer::Inner::Innermost.new(name: 'nested').save
      result = Outermost::Outer::Inner::Innermost.all
      result.first.name.should == 'nested'
    end
  end
end
