require 'spec_helper'

describe Diametric::Entity do
  describe "in a class" do
    subject { Person }

    it { should respond_to(:attribute) }
    it { should respond_to(:schema) }
    it { should respond_to(:from_query) }

    it "should generate a schema" do
      expected = [
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/index" => true,
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/email",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/many",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/birthday",
          :"db/valueType" => :"db.type/instant",
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/awesome",
          :"db/valueType" => :"db.type/boolean",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "Is this person awesome?",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/ssn",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/value",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/secret_name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/identity",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/bio",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/fulltext" => true,
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/parent",
          :"db/valueType" => :"db.type/ref",
          :"db/cardinality" => :"db.cardinality/many",
          :"db/doc" => "A person's parent",
          :"db.install/_attribute" => :"db.part/db" }
      ]
      Person.schema.each do |s|
        s.should == expected.shift
      end
    end
  end

  describe "in an instance" do
    subject { Person.new }
    let(:model) { Person.new }

    it_should_behave_like "ActiveModel"

    it { should respond_to(:tx_data) }

    it "should handle attributes correctly" do
      subject.name.should be_nil
      subject.name = "Clinton"
      subject.name.should == "Clinton"
    end
  end

  describe ".new" do
    it "should work without arguments" do
      Person.new.should be_a(Person)
    end

    it "should assign attributes based off argument keys" do
      person = Person.new(:name => "Dashiell D", :secret_name => "Monito")
      person.name.should == "Dashiell D"
      person.secret_name.should == "Monito"
    end
  end

  describe ".from_query" do
    it "should assign dbid and attributes" do
      goat = Goat.from_query([1, "Beans", DateTime.parse("1976/9/4")])
      goat.dbid.should == 1
      goat.name.should == "Beans"
      goat.birthday.should == DateTime.parse("1976/9/4")
    end
  end

  describe "#tx_data" do
    let(:goat) { Goat.new(:name => "Beans", :birthday => Date.parse("2002-04-15"))}

    describe "without a dbid" do
      it "should generate a transaction with a new tempid" do
        # Equivalence is currently wrong on EDN tagged values.
        tx = goat.tx_data.first
        tx.keys.should == [:"db/id", :"goat/name", :"goat/birthday"]
        tx[:"db/id"].to_edn.should match(%r"#db/id \[:db.part/user \-\d+\]")
        tx[:"goat/name"].should == "Beans"
        tx[:"goat/birthday"].should == goat.birthday
      end
    end

    describe "with a dbid" do
      it "should generate a transaction with the dbid" do
        goat.dbid = 1
        goat.tx_data.should == [
          { :"db/id" => 1,
            :"goat/name" => "Beans",
            :"goat/birthday" => goat.birthday
          }
        ]
      end

      it "should generate a transaction with only specified attributes" do
        goat.dbid = 1
        goat.tx_data(:name).should == [
          { :"db/id" => 1,
            :"goat/name" => "Beans"
          }
        ]
      end
    end
  end
end
