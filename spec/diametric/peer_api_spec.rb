require 'spec_helper'
require 'securerandom'

if is_jruby?
  describe Diametric::Persistence::Peer, :jruby => true do
    @db_name = "test-#{SecureRandom.uuid}"

    it 'should create database' do
      subject.create_database("datomic:mem://#{@db_name}").should be_true
    end

    context Diametric::Persistence::Peer do
      it 'should connect to the database' do
        subject.connect("datomic:mem://#{@db_name}").should be_true
      end

      it 'should get tempid' do
        subject.tempid(":db.part/db").to_s.should match(/#db\/id\[:db.part\/db\s-\d+\]/)
        subject.tempid(":db.part/user").to_s.should match(/#db\/id\[:db.part\/user\s-\d+\]/)
        subject.tempid(":db.part/user", -1).to_s.should match(/#db\/id\[:db.part\/user\s-1\]/)
      end

      it "should return uuid from squuid" do
        re = Regexp.new(/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/)
        subject.squuid.to_s.should match(re)
      end

      it "should return Fixnum from squuid_time_millis" do
        du = Diametric::Persistence::UUID.new
        subject.squuid_time_millis(du).class.should == Fixnum
      end
    end

    context Diametric::Persistence::Connection do
      @db_name = "test-#{SecureRandom.uuid}"
      let(:connection) { Diametric::Persistence::Peer.connect("datomic:mem://#{@db_name}") }
      let(:tempid) { Diametric::Persistence::Peer.tempid(":db.part/db") }
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
      before do
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
        @db_name = "test-#{SecureRandom.uuid}"
        @connection = Diametric::Persistence::Peer.connect("datomic:mem://#{@db_name}")

        @connection.transact(tx_data).get
        @connection.transact(user_data).get
      end

      it 'should get ids from datomic' do
        results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]", @connection.db)
        results.class.should == Diametric::Persistence::Set
        results.size.should be >= 3
        #puts results.inspect
      end

      it 'should get names from datomic' do
        results = Diametric::Persistence::Peer.q("[:find ?c ?name :where [?c :person/name ?name]]\
  ", @connection.db)
        results.collect { |r| r[1] }.should =~ ["Alice", "Bob", "Chris"]
        results.collect { |r| r if r.include?("Alice") }.compact.size.should == 1
      end

      it 'should get entity by id' do
        results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]",\
                                                 @connection.db)
        id = results.first.first
        @connection.db.entity(id).should be_true
      end

      it 'should get keys from entity id' do
        results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]",\
                                                 @connection.db)
        id = results.first.first
        entity = @connection.db.entity(id)
        entity.keys.should include(":person/name")
        #puts entity.keys
      end

      it 'should get value from entity id' do
        results = Diametric::Persistence::Peer.q("[:find ?c :where [?c :person/name]]",\
                                                 @connection.db)
        id = results.first.first
        entity = @connection.db.entity(id)
        value =  entity.get(entity.keys[0])
        value.should match(/Alice|Bob|Chris/)
        #puts value
      end
    end

    context Diametric::Persistence::Collection do
      before(:each) do
        vector =  Java::ClojureLang::PersistentVector.create(12, 23, 34, 45, 56, 67)
        @collection = Diametric::Persistence::Collection.wrap(vector)
      end

      it 'should return length' do
        @collection.length.should == 6
        @collection.size.should == 6
      end

      it 'should return string expression' do
        @collection.to_s.should == "[12 23 34 45 56 67]"
      end

      it 'should return object or nil for [index]' do
        @collection[0].should == Diametric::Persistence::Object.new(12)
        @collection[4].should == 56
        @collection[6].should == nil
        @collection[-3].should == 45
      end

      it 'should return new collection or nil for [start, length]' do
        @collection[1, 2].to_s.should == "[23 34]"
        @collection[7, 1].should == nil
        @collection[6, 1].to_s.should == "[]"
        @collection[-2, 5].to_s.should == "[56 67]"
        @collection[3, -1].should == nil
      end

      it 'should return new collection or nil for [range]' do
        @collection[1..3].to_s.should == "[23 34 45]"
        @collection[1...3].to_s.should == "[23 34]"
        @collection[5..10].to_s.should == "[67]"
        @collection[6..10].to_s.should == "[]"
        @collection[7..10].should == nil
      end
    end

    context Diametric::Persistence::Collection do
      before(:each) do
        java_set = java.util.HashSet.new([0, 1, 2, 3, 4, 5, 6])
        @set = Diametric::Persistence::Set.wrap(java_set)
      end

      it 'should return length' do
        @set.length.should == 7
        @set.size.should == 7
      end

      it 'should return false for empty test' do
        @set.empty?.should == false
      end

      it 'should test inclusion' do
        @set.include?(3).should == true
        @set.include?(-1).should == false
      end

      it 'should return first element' do
        [0, 1, 2, 3, 4, 5, 6].should include(@set.first)
      end

      it 'should iterate elements' do
        @set.each do |e|
          [0, 1, 2, 3, 4, 5, 6].should include(e)
        end
      end

      it 'should return collected array' do
        ret = @set.collect { |i| i * i }
        ret.should =~ [0, 1, 4, 9, 16, 25, 36]
      end

      it 'should group the element' do
        ret = @set.group_by { |i| i % 3 }
        ret[0].should =~ [0, 3, 6]
        ret[1].should =~ [1, 4]
        ret[2].should =~ [2, 5]
      end

      it 'should group by the length' do
        s = java.util.HashSet.new(["Homer", "Marge", "Bart", "Lisa", "Abraham", "Herb"])
        set_of_words = Diametric::Persistence::Set.wrap(s)
        ret = set_of_words.group_by {|w| w.length }
        ret[4].should =~ ["Bart", "Lisa", "Herb"]
        ret[5].should =~ ["Homer", "Marge"]
        ret[7].should =~ ["Abraham"]
      end

      it 'should group each array by the first element' do
        s = java.util.HashSet.new([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
        set_of_ary = Diametric::Persistence::Set.wrap(s)
        ret = set_of_ary.group_by(&:first)
        ret[1].should == [[1, 2, 3]]
        ret[4].should == [[4, 5, 6]]
        ret[7].should == [[7, 8, 9]]
      end
    end
  end
end

def user_part_tempid
  Diametric::Persistence::Peer.tempid(":db.part/user")
end
