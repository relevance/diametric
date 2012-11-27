require 'spec_helper'

# Prevent CRuby from blowing up
module Diametric
  module Persistence
    module Peer
    end
  end
end

describe Diametric::Persistence do
  let(:settings) { { :uri => 'http://example.com:9000' } }
  let(:rest_class) { Diametric::Persistence::REST }

  describe ".establish_base_connection" do
    before { Diametric::Persistence.stub(:persistence_class => rest_class) }

    it "connects" do
      settings = { :uri => 'http://example.com:9000' }
      rest_class.should_receive(:connect).with(settings)

      Diametric::Persistence.establish_base_connection(settings)
    end

    it "records the base persistence class" do
      rest_class.stub(:connect)
      Diametric::Persistence.establish_base_connection(settings)
      Diametric::Persistence.instance_variable_get(:"@_persistence_class").should == rest_class
    end
  end

  describe ".included" do
    before { Diametric::Persistence.stub(:persistence_class => rest_class) }

    it "includes the recorded base persistence class" do
      class FooEntity; end
      FooEntity.should_receive(:send).with(:include, rest_class)
      Diametric::Persistence.instance_variable_set(:"@_persistence_class", rest_class)

      class FooEntity
        include Diametric::Persistence
      end
    end
  end

  describe ".persistence_class" do
    it "returns REST for REST-like options" do
      klass = Diametric::Persistence.persistence_class("http://localhost:9000")
      klass.should be Diametric::Persistence::REST
      Diametric::Persistence.rest?.should == true
    end

    it "returns Peer for Peer-like options", :jruby do
      klass = Diametric::Persistence.persistence_class("datomic:free://localhost:9000/sample")
      klass.should be Diametric::Persistence::Peer
      Diametric::Persistence.peer?.should == true
    end
  end
end
