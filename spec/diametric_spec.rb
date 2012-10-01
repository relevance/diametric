require 'spec_helper'

class Person
  include Diametric

  attr :name, String, :index => true
  attr :email, String, :cardinality => :many
  attr :birthday, DateTime
  attr :awesome, :boolean, :doc => "Is this person awesome?"
  attr :ssn, String, :unique => :value
  attr :secret_name, String, :unique => :identity
  attr :bio, String, :fulltext => true
end

class Goat
  include Diametric

  attr :name, String
  attr :birthday, DateTime
end

describe Diametric do
  describe "in a class" do
    subject { Person }

    it { should respond_to(:attr) }
    it { should respond_to(:schema) }
    it { should respond_to(:query_data) }
    it { should respond_to(:from_query) }

    it "should generate a schema" do
      Person.schema.should == [
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
          :"db.install/_attribute" => :"db.part/db" }
      ]
    end
  end

  describe "in an instance" do
    subject { Person.new }

    it { should respond_to(:tx_data) }
  end

  describe "queries" do
    it "should generate a query given no arguments" do
      Goat.query_data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :from, ~"\$",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        {}
      ]
    end

    it "should generate a query given an argument" do
      Goat.query_data(:name => "Beans").should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :from, ~"\$", ~"?name",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        {:args => ["Beans"]}
      ]
    end

    it "should generate a query given multiple arguments" do
      bday = DateTime.parse("2003-09-04 11:30 AM")

      Goat.query_data(:name => "Beans", :birthday => bday).should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :from, ~"\$", ~"?name", ~"?birthday",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        {:args => ["Beans", bday]}
      ]
    end
  end
end
