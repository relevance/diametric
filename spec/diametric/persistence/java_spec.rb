require 'spec_helper'
require 'diametric/persistence/java' if RUBY_ENGINE == 'jruby'

# Prevent CRuby from blowing up
module Diametric
  module Persistence
    module Java
    end
  end
end

describe Diametric::Persistence::Java, :jruby do
  class Rat
    include Diametric::Entity
    include Diametric::Persistence::Java

    attribute :name, String, :index => true
  end

  let(:db_uri) { 'datomic:mem://hello' }

  it "can connect to a Datomic database" do
    subject.connect(db_uri)
    subject.connection.should be_a(Java::DatomicPeer::LocalConnection)
  end

  describe "an instance" do
    let(:rat) { Rat.new }

    before(:all) do
      subject.connect(db_uri)
      Diametric::Persistence::Java.create_schemas
    end

    it "can save" do
      rat.name = "Wilbur"
      rat.save.should be_true
      rat.should be_persisted
    end

    context "that is saved in Datomic" do
      before(:each) do
        rat.name = "Wilbur"
        rat.save
      end

      it "can find it by dbid" do
        rat2 = Rat.get(rat.dbid)
        rat2.should_not be_nil
        rat2.name.should == rat.name
        rat2.should == rat
      end

      it "can save it back to Datomic with changes" do
        rat.name = "Mr. Wilbur"
        rat.save.should be_true

        rat2 = Rat.get(rat.dbid)
        rat2.name.should == "Mr. Wilbur"
      end

      it "can find it by attribute" do
        rat2 = Rat.first(:name => "Wilbur")
        rat2.should_not be_nil
        rat2.dbid.should == rat.dbid
        rat2.should == rat
      end

      it "can find all matching conditions" do
        rats = Rat.where(:name => "Wilbur").all
        rats.should == [rat]
      end
    end
  end
end
