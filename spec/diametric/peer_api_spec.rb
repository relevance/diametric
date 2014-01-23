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
        subject.tempid(:"db.part/db").to_s.should match(/#db\/id\[:db.part\/db\s-\d+\]/)
        subject.tempid(:"db.part/user").to_s.should match(/#db\/id\[:db.part\/user\s-\d+\]/)
        subject.tempid(:"db.part/user", -1).to_s.should match(/#db\/id\[:db.part\/user\s-1\]/)
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
      let(:tempid) { Diametric::Persistence::Peer.tempid(:"db.part/db") }
      let(:tx_data) {
        [{
           :"db/id" => tempid,
           :"db/ident" => :"person/name",
           :"db/valueType" => :"db.type/string",
           :"db/cardinality" => :"db.cardinality/one",
           :"db/doc" => "A person's name",
           :"db.install/_attribute" => :"db.part/db"
         }]
      }
      let(:user_data) {
        [{:"db/id" => user_part_tempid, :"person/name" => "Alice"},
         {:"db/id" => user_part_tempid, :"person/name" => "Bob"},
         {:"db/id" => user_part_tempid, :"person/name" => "Chris"}]
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
             :"db/id" => Diametric::Persistence::Peer.tempid(:"db.part/db"),
             :"db/ident" => :"person/name",
             :"db/valueType" => :"db.type/string",
             :"db/cardinality" => :"db.cardinality/one",
             :"db/doc" => "A person's name",
             :"db.install/_attribute" => :"db.part/db"
           }]
        user_data = 
          [{:"db/id" => Diametric::Persistence::Peer.tempid(:"db.part/user"), :"person/name" => "Alice"},
           {:"db/id" => Diametric::Persistence::Peer.tempid(:"db.part/user"), :"person/name" => "Bob"},
           {:"db/id" => Diametric::Persistence::Peer.tempid(:"db.part/user"), :"person/name" => "Chris"}]
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
      before(:all) do
        vector =  Java::ClojureLang::PersistentVector.create(12, 23, 34, 45, 56, 67)
        @collection = Diametric::Persistence::Collection.wrap(vector)
        @seq = Diametric::Persistence::Collection.be_lazy(vector)
        vector2 =  Java::ClojureLang::PersistentVector.create(12, false, 23, nil, 34, 45, nil, 56, nil, false, 67)
        @collection2 = Diametric::Persistence::Collection.wrap(vector2)
        @seq2 = Diametric::Persistence::Collection.be_lazy(vector2)
        empty_vector =  Java::ClojureLang::PersistentVector.create()
        @empty_collection = Diametric::Persistence::Collection.wrap(empty_vector)
        @empty_seq = Diametric::Persistence::Collection.be_lazy(empty_vector)
      end

      it 'should raise error for & method' do
        expect { @collection & [100, 200] }.to raise_error(RuntimeError)
      end

      it 'should raise error for assoc method' do
        expect { @collection.assoc("something") }.to raise_error(RuntimeError)
      end

      it 'should repeat elements by * method' do
        @collection.*(2).should == [12, 23, 34, 45, 56, 67, 12, 23, 34, 45, 56, 67]
        @collection.*(",").should == "12,23,34,45,56,67"
      end

      it 'should concat other array' do
        @collection.+([100, 200]).should == [12, 23, 34, 45, 56, 67, 100, 200]
      end

      it 'should get difference from other array' do
        @collection.-([12, 45, 67]).should == [23, 34, 56]
      end

      it 'should return length' do
        @collection.length.should == 6
        @collection.size.should == 6
        @seq.length.should == 6
        @seq.size.should == 6
      end

      it 'should return string expression' do
        @collection.to_s.should == "[12, 23, 34, 45, 56, 67]"
        @seq.to_s.should == "[12, 23, 34, 45, 56, 67]"
      end

      it 'should return object or nil for [index]' do
        @collection[0].should == 12
        @collection[4].should == 56
        @collection[6].should == nil
        @collection[-3].should == 45
        @collection[0].should == 12
        @collection[4].should == 56
        @collection[6].should == nil
        @collection[-3].should == 45

        @seq[0].should == 12
        @seq[4].should == 56
        @seq[6].should == nil
        @seq[-3].should == 45
        @seq[0].should == 12
        @seq[4].should == 56
        @seq[6].should == nil
        @seq[-3].should == 45
      end

      it 'should return new collection or nil for [start, length]' do
        @collection[1, 2].should == [23, 34]
        @collection[7, 1].should == nil
        @collection[6, 1].should == []
        @collection[-2, 5].should == [56, 67]
        @collection[3, -1].should == nil

        @seq[1, 2].should == [23, 34]
        @seq[7, 1].should == nil
        @seq[6, 1].should == []
        @seq[-2, 5].should == [56, 67]
        @seq[3, -1].should == nil
      end

      it 'should return new collection or nil for [range]' do
        @collection[1..3].should == [23, 34, 45]
        @collection[1...3].should == [23, 34]
        @collection[5..10].should == [67]
        @collection[6..10].should == []
        @collection[7..10].should == nil

        @seq[1..3].should == [23, 34, 45]
        @seq[1...3].should == [23, 34]
        @seq[5..10].should == [67]
        @seq[6..10].should == []
        @seq[7..10].should == nil
      end

      it 'should return object or nil at(index)' do
        @collection.at(4).should == 56
        @collection.at(-1).should == 67

        @seq.at(4).should == 56
        @seq.at(-1).should == 67
      end

      it 'should raise error for bsearch method' do
        expect { @collection.bsearch {|x| x} }.to raise_error(RuntimeError)
      end

      it 'should raise error for clear method' do
        expect { @collection.clear }.to raise_error(RuntimeError)
      end

      it 'should return new array for collect or map method' do
        @collection.collect {|x| x > 40 }.should == [false, false, false, true, true, true]
        @collection.map(&:to_s).should == ["12", "23", "34", "45", "56", "67"]

        @seq.collect {|x| x > 40 }.should == [false, false, false, true, true, true]
        @seq.map(&:to_s).should == ["12", "23", "34", "45", "56", "67"]
      end

      it 'should raise error for collect! or map! method' do
        expect { @collection.collect! {|x| x > 40 } }.to raise_error(RuntimeError)
        expect { @collection.map!(&:to_s) }.to raise_error(RuntimeError)
      end

      it 'should strip nil element out from vector but not false for compact method' do
        @collection2.compact.should == [12, false, 23, 34, 45, 56, false, 67]

        @seq2.compact.should == [12, false, 23, 34, 45, 56, false, 67]
      end

      it 'should raise error for compact! method' do
        expect { @collection.compact! }.to raise_error(RuntimeError)
      end

      it 'should raise error for concat method' do
        expect { @collection.concat([100, 200]) }.to raise_error(RuntimeError)
      end

      it 'should count speicfied object for count method' do
        @collection.count.should == 6
        @collection2.count(false).should == 2
        @collection2.count(100).should == 0
        @collection2.count(67).should == 1
        @collection2.count(nil).should == 3

        @seq.count.should == 6
        @seq2.count(false).should == 2
        @seq2.count(100).should == 0
        @seq2.count(67).should == 1
        @seq2.count(nil).should == 3
      end

      it 'should raise error for cycle method' do
        expect { @collection.cycle { |x| x } }.to raise_error(RuntimeError)
        expect { @collection.cycle(2) { |x| x } }.to raise_error(RuntimeError)
      end

      it 'should raise error for delete method' do
        expect { @collection.delete(12) }.to raise_error(RuntimeError)
        expect { @collection.delete(100) { "not found" } }.to raise_error(RuntimeError)
      end

      it 'should raise error for delete_at and slice! method' do
        expect { @collection.delete_at(2) }.to raise_error(RuntimeError)
        expect { @collection.slice!(2) }.to raise_error(RuntimeError)
        expect { @collection.slice!(2, 2) }.to raise_error(RuntimeError)
        expect { @collection.slice!(2, 2) }.to raise_error(RuntimeError)
        expect { @collection.slice!(0...2) }.to raise_error(RuntimeError)
      end

      it 'should raise error for delete_if and reject! method' do
        expect { @collection.delete_if {|x| x > 30} }.to raise_error(RuntimeError)
        expect { @collection.reject! {|x| x < 30} }.to raise_error(RuntimeError)
      end

      it 'should drop or take elements' do
        @collection.drop(2).should == [34, 45, 56, 67]
        @collection.take(3).should == [45, 56, 67]

        @seq.drop(2).should == [34, 45, 56, 67]
        @seq.take(3).should == [45, 56, 67]
      end

      it 'should drop or take elements while block returns true' do
        @collection.drop_while {|x| x < 30}.should == [34, 45, 56, 67]
        @collection2.take_while {|x| x != nil}.should == [nil, 34, 45, nil, 56, nil, false, 67]

        @seq.drop_while {|x| x < 30}.should == [34, 45, 56, 67]
        @seq2.take_while {|x| x != nil}.should == [nil, 34, 45, nil, 56, nil, false, 67]
      end

      it 'should iterate elements' do
        result = []
        @collection.each {|e| result << e.to_s}
        result.should == ["12", "23", "34", "45", "56", "67"]

        result = []
        @collection.each_index {|e| result << e.to_s}
        result.should == ["0", "1", "2", "3", "4", "5"]

        result = []
        @seq.each {|e| result << e.to_s}
        result.should == ["12", "23", "34", "45", "56", "67"]

        result = []
        @seq.each_index {|e| result << e.to_s}
        result.should == ["0", "1", "2", "3", "4", "5"]
      end

      it 'should return true or false for empty test' do
        @collection.empty?.should == false
        @empty_collection.empty?.should == true

        @seq.empty?.should == false
        @empty_seq.empty?.should == true
      end

      it 'should return true or false for eql? test' do
        @collection.eql?([12, 23, 34, 45, 56, 67]).should be_true
        @collection.eql?(@collection2).should be_false

        @seq.eql?([12, 23, 34, 45, 56, 67]).should be_true
        @seq.eql?(@seq2).should be_false
      end

      it 'should fetch a value or raise IndexError/default/block value' do
        @collection.fetch(1).should == 23
        @collection.fetch(-1).should == 67
        @collection.fetch(100, "have a nice day").should == "have a nice day"
        message = ""
        @collection.fetch(-100) {|i| message = "#{i} is out of bounds"}
        message.should == "-100 is out of bounds"

        @seq.fetch(1).should == 23
        @seq.fetch(-1).should == 67
        @seq.fetch(100, "have a nice day").should == "have a nice day"
        message = ""
        @seq.fetch(-100) {|i| message = "#{i} is out of bounds"}
        message.should == "-100 is out of bounds"
      end

      it 'should raise error for fill method' do
        expect { @collection.fill("x") }.to raise_error(RuntimeError)
        expect { @collection.fill("z", 2, 2) }.to raise_error(RuntimeError)
        expect { @collection.fill("y", 0..1) }.to raise_error(RuntimeError)
        expect { @collection.fill {|i| i*i} }.to raise_error(RuntimeError)
        expect { @collection.fill(-2) {|i| i*i} }.to raise_error(RuntimeError)
      end

      it 'should return index of the first matched object' do
        @collection.find_index(34).should == 2
        @collection2.find_index(nil).should == 3
        @collection.find_index(100).should == nil
        @collection.find_index { |x| x % 7 == 0 }.should == 4
        @collection.find_index { |x| x < 0 }.should == nil
        @collection.index(45).should == 3
        @collection2.index(false).should == 1
        @collection2.index(true).should == nil
        @collection.index { |x| x.odd? }.should == 1
        @collection.index { |x| x > 100 }.should == nil

        @seq.find_index(34).should == 2
        @seq2.find_index(nil).should == 3
        @seq.find_index(100).should == nil
        @seq.find_index { |x| x % 7 == 0 }.should == 4
        @seq.find_index { |x| x < 0 }.should == nil
        @seq.index(45).should == 3
        @seq2.index(false).should == 1
        @seq2.index(true).should == nil
        @seq.index { |x| x.odd? }.should == 1
        @seq.index { |x| x > 100 }.should == nil
      end

      it 'should return first element or first n elements' do
        @collection.first.should == 12
        @collection.first(3).should == [12, 23, 34]
        @collection.first(100).should == [12, 23, 34, 45, 56, 67]

        @seq.first.should == 12
        @seq.first(3).should == [12, 23, 34]
        @seq.first(100).should == [12, 23, 34, 45, 56, 67]
      end

      it 'should raise error for flatten/flatten! methods' do
        expect { @collection.flatten }.to raise_error(RuntimeError)
        expect { @collection.flatten(2) }.to raise_error(RuntimeError)
        expect { @collection.flatten! }.to raise_error(RuntimeError)
        expect { @collection.flatten(100) }.to raise_error(RuntimeError)
      end

      it 'should return true from frozen? method' do
        @collection.frozen?.should == true

        @seq.frozen?.should == true
      end

      it 'should return truethiness for include? method' do
        @collection.include?(56).should be_true
        @collection2.include?(nil).should be_true
        @collection2.include?(false).should be_true
        @collection.include?("a").should be_false

        @seq.include?(56).should be_true
        @seq2.include?(nil).should be_true
        @seq2.include?(false).should be_true
        @seq.include?("a").should be_false
      end

      it 'should raise error for replace method' do
        expect { @collection.replace(["x", "y", "z"]) }.to raise_error(RuntimeError)
      end

      it 'should raise error for insert method' do
        expect { @collection.insert(2, 99) }.to raise_error(RuntimeError)
        expect { @collection.insert(-2, 1, 2, 3) }.to raise_error(RuntimeError)
      end

      it 'should return string representation' do
        @collection.inspect.should == "[12, 23, 34, 45, 56, 67]"

        @seq.inspect.should == "[12, 23, 34, 45, 56, 67]"
      end

      it 'should return joined string' do
        @collection.join.should == "122334455667"
        @collection.join(", ").should == "12, 23, 34, 45, 56, 67"

        @seq.join.should == "122334455667"
        @seq.join(", ").should == "12, 23, 34, 45, 56, 67"
      end

      it 'should raise error for keep_if and select! methods' do
        expect { @collection.keep_if {|v| v == 0} }.to raise_error(RuntimeError)
        expect { @collection.keep_if }.to raise_error(RuntimeError)
        expect { @collection.select! {|v| v == 0} }.to raise_error(RuntimeError)
        expect { @collection.select! }.to raise_error(RuntimeError)
      end

      it 'should return last elements' do
        @collection.last.should == 67
        @collection.last(2).should == [56, 67]

        @seq.last.should == 67
        @seq.last(2).should == [56, 67]
      end
    end

    context Diametric::Persistence::Set do
      before(:each) do
        java_set = java.util.HashSet.new([0, 1, 2, 3, 4, 5, 6])
        @set = Diametric::Persistence::Set.wrap(java_set)
        java_set2 = java.util.HashSet.new([0, 11, 2, 3, 44, 5, 66])
        @set2 = Diametric::Persistence::Set.wrap(java_set)
      end

      it 'should return intersection'  do
        @set.&(Set.new([3, 6, 9])).should == [3, 6].to_set
        @set.intersection(Set.new([0, 4, 8])).should == [0, 4].to_set
      end

      it 'should return union' do
        @set.|(Set.new([3, 6, 9])).should == [0, 1, 2, 3, 4, 5, 6, 9].to_set
        @set.union(Set.new([0, 4, 8])).should == [0, 1, 2, 3, 4, 5, 6, 8].to_set
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
  Diametric::Persistence::Peer.tempid(:"db.part/user")
end
