require 'spec_helper'
require 'diametric/persistence/rest'

class Mouse
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String, :index => true
  attribute :age, Integer
end

describe Diametric::Persistence::REST, :integration do
  let(:db_uri) { ENV['DATOMIC_URI'] || 'http://localhost:9000' }
  let(:storage) { ENV['DATOMIC_STORAGE'] || 'test' }
  let(:dbname) { ENV['DATOMIC_NAME'] || "test-#{Time.now.to_i}" }

  it "can connect to a Datomic database" do
    subject.connect(db_uri, storage, dbname)
    subject.connection.should be_a(Datomic::Client)
  end

  describe "an instance" do
    let(:mouse) { Mouse.new }

    before(:all) do
      subject.connect(db_uri, storage, dbname)
      Diametric::Persistence::REST.create_schemas
    end

    it "can save" do
      # TODO deal correctly with nil values
      mouse.name = "Wilbur"
      mouse.age = 2
      mouse.save.should be_true
      mouse.should be_persisted
    end

    context "that is saved in Datomic" do
      before(:each) do
        mouse.name = "Wilbur"
        mouse.age = 2
        mouse.save
      end

      it "can find it by dbid" do
        mouse2 = Mouse.get(mouse.dbid)
        mouse2.should_not be_nil
        mouse2.name.should == mouse.name
        mouse2.should == mouse
      end

      it "can save it back to Datomic with changes" do
        mouse.name = "Mr. Wilbur"
        mouse.save.should be_true

        mouse2 = Mouse.get(mouse.dbid)
        mouse2.name.should == "Mr. Wilbur"
      end

      it "can find it by attribute" do
        mouse2 = Mouse.first(:name => "Wilbur")
        mouse2.should_not be_nil
        mouse2.dbid.should == mouse.dbid
        mouse2.should == mouse
      end

      it "can find all matching conditions" do
        mice = Mouse.where(:name => "Wilbur").where(:age => 2).all
        mice.should == [mouse]
      end

      it "can filter entities" do
        mice = Mouse.filter(:<, :age, 3).all
        mice.should == [mouse]

        mice = Mouse.filter(:>, :age, 3).all
        mice.should == []
      end
    end
  end
end
