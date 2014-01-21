require 'spec_helper'
require 'diametric/persistence/peer'
require 'securerandom'

describe Diametric::Persistence::Peer, :integration => true, :jruby => true do
  context Rat do
    before do
      datomic_uri = "datomic:mem://rat-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Rat.create_schema(@conn).get
    end

    after do
      @conn.release
    end

    it_behaves_like "persistence API" do
      let(:model_class) { Rat }
    end
  end
end
