require 'spec_helper'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

describe Diametric::Persistence::Peer do
  it 'should create database' do
    subject.create_database("datomic:mem://sample").should be_true
  end

  context Diametric::Persistence::Peer do
    it 'should connect to the database' do
      subject.connect("datomic:mem://sample").should be_true
    end

    it 'should get tempid' do
      subject.tempid(":db.part/db").to_s.should match(/#db\/id\[:db.part\/db\s-\d+\]/)
      subject.tempid(":db.part/user").to_s.should match(/#db\/id\[:db.part\/user\s-\d+\]/)
    end
  end

  context Diametric::Persistence::Connection do
    let(:connection) { Diametric::Persistence::Peer.connect("datomic:mem://sample") }
    let(:tempid) { Diametric::Persistence::Peer.tempid(":db.part/db") }
    let(:user_part_tempid) { Diametric::Persistence::Peer.tempid(":db.part/user") } 
    let(:tx_data) {
      [{
        ":db/id" => tempid,
        ":db/ident" => ":person/name",
        ":db/valueType" => ":db.type/string",
        ":db/cardinality" => ":db.cardinality/one",
        ":db/doc" => "A person's name",
        ":db.install/_attribute" => ":db.part/db"
      }]
    }
    let(:user_data) {
      [{":db/id" => user_part_tempid, ":person/name" => "Alice"},
       {":db/id" => user_part_tempid, ":person/name" => "Bob"},
       {":db/id" => user_part_tempid, ":person/name" => "Chris"}]
    }

    it 'should transact schema' do
      connection.transact(tx_data).class.should == Diametric::Persistence::ListenableFuture
    end

    it 'should get future object for schema' do
      connection.transact(tx_data).get.should be_true
    end

    it 'should transact data' do
      connection.transact(tx_data).get
      connection.transact(user_data).get.should be_true
    end

    it 'should resolve tempid' do
      tmp_tempid = user_part_tempid
      connection.transact(tx_data).get
      map = connection.transact([{":db/id" => tmp_tempid, ":person/name" => "Alice"}]).get
      resolved_tempid = Diametric::Persistence::Peer.resolve_tempid(map,  tmp_tempid)
      resolved_tempid.should be_true
      resolved_tempid.to_s.should match(/\d+/)
      #puts "resolved_tempid: #{resolved_tempid}"
    end
  end

  context 'Diametric query' do
    let(:connection) { Diametric::Persistence::Peer.connect("datomic:mem://sample") }
    before(:all) {
      tx_data =
      [{
         ":db/id" => Diametric::Persistence::Peer.tempid(":db.part/db"),
         ":db/ident" => ":person/name",
         ":db/valueType" => ":db.type/string",
         ":db/cardinality" => ":db.cardinality/one",
         ":db/doc" => "A person's name",
         ":db.install/_attribute" => ":db.part/db"
       }]
      user_data = 
      [{":db/id" => Diametric::Persistence::Peer.tempid(":db.part/user"), ":person/name" => "Alice"},
       {":db/id" => Diametric::Persistence::Peer.tempid(":db.part/user"), ":person/name" => "Bob"},
       {":db/id" => Diametric::Persistence::Peer.tempid(":db.part/user"), ":person/name" => "Chris"}]
      connection.transact(tx_data).get
      connection.transact(user_data).get
    }

    it 'should get ids from datomic' do
      results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]", connection.db)
      results.class.should == Array
      results.size.should be >= 3
      #puts results.inspect
    end

    it 'should get names from datomic' do
      results = Diametric::Persistence::Peer.q("[:find ?c ?name :where [?c :person/name ?name]]\
  ", connection.db)
      results.flatten.should include("Alice")
      results.flatten.should include("Bob")
      results.flatten.should include("Chris")
      #puts results.inspect
    end

    it 'should get entity by id' do
      results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]",\
 connection.db)
      id = results[0][0]
      connection.db.entity(id).should be_true
    end

    it 'should get keys from entity id' do
      results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]",\
 connection.db)
      id = results[0][0]
      entity = connection.db.entity(id)
      entity.keys.should include(":person/name")
      #puts entity.keys
    end

    it 'should get value from entity id' do
      results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]",\
 connection.db)
      id = results[0][0]
      entity = connection.db.entity(id)
      value =  entity.get(entity.keys[0])
      value.should match(/Alice|Bob|Chris/)
      #puts value
    end
  end
end

end
