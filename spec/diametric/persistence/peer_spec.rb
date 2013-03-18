require 'spec_helper'

# Prevent CRuby from blowing up
module Diametric
  module Persistence
    module Peer
    end
  end
end

describe Diametric::Persistence::Peer, :jruby do
  before (:all) do
      @db_uri = "datomic:mem://hello-#{Time.now.to_i}"
  end

  class Rat
    include Diametric::Entity
    include Diametric::Persistence::Peer

    attribute :name, String, :index => true
    attribute :age, Integer
  end

  it "can connect to a Datomic database" do
    connection = subject.connect(:uri => @db_uri)
    connection.should be_a(Diametric::Persistence::Connection)
  end

  it_behaves_like "persistence API" do
    let(:model_class) { Rat }

    before(:all) do
      @connection = Diametric::Persistence::Peer.connect(:uri => @db_uri)
      Diametric::Persistence::Peer.create_schemas(@connection)
    end
  end
end
