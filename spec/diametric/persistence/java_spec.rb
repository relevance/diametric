require 'spec_helper'

if RUBY_ENGINE == 'jruby'
  require 'diametric/persistence/java'

  class Mouse
    include Diametric::Entity
    include Diametric::Persistence::Java

    attribute :name, String, :index => true
  end
end

describe Diametric::Persistence::Java, :java do
  let(:db_uri) { 'datomic:mem://hello' }

  it "can connect to a Datomic database" do
    subject.connect(db_uri)
    subject.connection.should be_a(Java::DatomicPeer::LocalConnection)
  end

  describe "an instance" do
    let(:mouse) { Mouse.new }

    before(:all) do
      subject.connect(db_uri)
      Diametric::Persistence::Java.create_schemas
    end

    it "can save" do
      mouse.name = "Wilbur"
      mouse.save.should be_true
      mouse.should be_persisted
    end

    context "that is saved in Datomic" do
      before(:each) do
        mouse.name = "Wilbur"
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
        mice = Mouse.where(:name => "Wilbur")
        mice.should == [mouse]
      end
    end
  end
end
