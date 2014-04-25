require 'spec_helper'

describe Diametric::Bucket, :integration => true do
  context Rat, :jruby => true do
    before do
      datomic_uri = "datomic:mem://bucket-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
      Rat.create_schema(@conn).get
      Cage.create_schema(@conn).get
    end

    after do
      @conn.release
    end

    it_behaves_like "bucket API" do
      let(:model_class) { Rat }
      let(:parent_class) { Cage }
    end
  end

  context Mouse do
    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "bucket-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
      Diametric::Persistence::REST.create_schemas
      @conn = Diametric::Persistence::REST.connection
    end

    it_behaves_like "bucket API" do
      let(:model_class) { Mouse }
      let(:parent_class) { Box }
    end
  end
end
