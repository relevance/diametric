require 'spec_helper'
require 'diametric/persistence/peer'
require 'securerandom'

describe Diametric::Persistence::Peer, :jruby do
  before do
    @db_uri = "datomic:mem://hello-#{SecureRandom.uuid}"
  end

  it "can connect to a Datomic database" do
    connection = subject.connect(:uri => @db_uri)
    connection.should be_a(Diametric::Persistence::Connection)
  end

  it_behaves_like "persistence API" do
    let(:model_class) { Rat }

    before do
      @connection = Diametric::Persistence::Peer.connect(:uri => @db_uri)
      Diametric::Persistence::Peer.create_schemas(@connection)
    end

    after do
      @connection.release
      Diametric::Persistence::Peer.shutdown(true)
    end
  end
end
