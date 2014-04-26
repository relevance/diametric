require 'spec_helper'

describe Diametric::Persistence::Function, :integration => true, :jruby => true do
  context "Peer" do
    let(:hello) {
      {lang: :clojure,
        params: [:name],
        code: %{(str "Hello, " name)}
      }
    }

    it "creates datomic function" do
      function = Diametric::Persistence::Peer.function(hello)
      function.should_not be_nil
      function.class.should == Diametric::Persistence::Function
      function.to_java.class.should == Java::DatomicFunction::Function
      function.lang.should == ":clojure"
      function.params.should == "[name]"
      function.code.should == "(str \"Hello, \" name)"
    end

    it "runs as s clojure function" do
      function = Diametric::Persistence::Peer.function(hello)
      function.to_java.invoke("John").should == "Hello, John"
    end
  end

  context "with created function" do
    let(:hello_with_info) {
      { name: :hello,
        doc: "Just says hello to 'name'",
        lang: :clojure,
        params: [:name],
        code: %{(str "Hello, " name)}
      }
    }

    before do
      datomic_uri = "datomic:mem://function-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "saves in database" do
      result = Diametric::Persistence::Function.create(hello_with_info, @conn)
      result.should_not be_nil
    end
  end

  context "with saved function" do
    let(:hello_with_info) {
      { name: :hello,
        doc: "Just says hello to 'name'",
        lang: :clojure,
        params: [:name],
        code: %{(str "Hello, " name)}
      }
    }

    before do
      datomic_uri = "datomic:mem://function-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Diametric::Persistence::Function.create(hello_with_info, @conn)
    end

    after do
      @conn.release
    end

    it "can be added to an entity and run" do
      Rat.db_functions << :hello
      Rat.hello(@conn, "Nancy").should == "Hello, Nancy"
    end
  end

  context "with saved transaction function" do
    let(:inc_fn) {
      { name: :inc_fn,
        doc: "Increments the given attribute value by amount",
        lang: :clojure,
        params: [:db, :id, :attr, :amount],
        code: %{(let [e (datomic.api/entity db id) orig (attr e 0)]
                  [[:db/add id attr (+ orig amount) ]])}
      }
    }

    describe "Peer" do
      before do
        datomic_uri = "datomic:mem://function-#{SecureRandom.uuid}"
        @conn = Diametric::Persistence::Peer.connect(datomic_uri)
        Diametric::Persistence::Function.create(inc_fn, @conn)
        Rat.create_schema(@conn)
      end

      after do
        @conn.release
      end

      it "can be added to an entity and run" do
        jay = Rat.new({name: "Jay", age: 10})
        jay.save
        jay.transaction_functions << :inc_fn
        jay = jay.inc_fn(@conn, :age, 3)
        jay.age.should == 13
      end
    end

    describe "REST" do
      before do
        @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
        @storage = ENV['DATOMIC_STORAGE'] || 'free'
        @dbname = ENV['DATOMIC_NAME'] || "function-#{SecureRandom.uuid}"
        @connection_options = {
          :uri => @db_uri,
          :storage => @storage,
          :database => @dbname
        }
        Diametric::Persistence::REST.connect(@connection_options)
        Diametric::Persistence::REST.create_schemas
      end

      it "can create and save transaction funcrion" do
        result = Diametric::Persistence::Function.create(inc_fn, nil)
        result.should_not be_nil
      end

      context "with saved transaction function" do
        before do
          Diametric::Persistence::Function.create(inc_fn, nil)
        end

        it "can be added to an entity and run" do
          juliet = Mouse.new({name: "Juliet", age: 13})
          juliet.save
          juliet.transaction_functions << :inc_fn
          juliet = juliet.inc_fn(nil, :age, 4)
          pending("REST fails to transact function")
          juliet.age.should == 17
        end
      end
    end
  end
end
