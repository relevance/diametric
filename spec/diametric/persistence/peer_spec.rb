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

  context ScarletMacaw do
    before do
      datomic_uri = "datomic:mem://scarlet-macaw-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      ScarletMacaw.create_schema(@conn).get
    end

    after do
      @conn.release
    end

    it_behaves_like "supports various types" do
      let(:model_class) { ScarletMacaw }
    end
  end

  context MyWords do
    before do
      datomic_uri = "datomic:mem://my-words-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      MyWords.create_schema(@conn).get
    end

    after do
      @conn.release
    end

    it_behaves_like "supports cardinality many" do
      let(:model_class) { MyWords }
    end
  end

  context Cage do
    before do
      datomic_uri = "datomic:mem://cage-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Cage.create_schema(@conn).get
      Rat.create_schema(@conn).get
    end

    after do
      @conn.release
    end

    it_behaves_like "supports has_one association" do
      let(:parent_class) { Cage }
      let(:child_class) { Rat }
    end
  end

  context BigCage do
    before do
      datomic_uri = "datomic:mem://big-cage-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      BigCage.create_schema(@conn).get
      Rat.create_schema(@conn).get
    end

    after do
      @conn.release
    end

    it_behaves_like "supporting has_many association" do
      let(:parent_class) { BigCage }
      let(:child_class) { Rat }
    end
  end
end
