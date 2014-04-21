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
      function = Diametric::Persistence::Function.create_function(hello_with_info, @conn)
      function.name.should == :hello
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
      @function = Diametric::Persistence::Function.create_function(hello_with_info, @conn)
    end

    after do
      @conn.release
    end

    it "can be added to an entity and run" do
      Rat.add_function(@function)
      Rat.hello("Nancy").should == "Hello, Nancy"
    end
  end
end
