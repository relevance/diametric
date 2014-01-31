require 'spec_helper'
require 'diametric/persistence/rest'
require 'securerandom'

describe Diametric::Persistence::REST, :integration do
  context "simple queries for a simple schema" do
    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "mouse-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
    end

    it "can connect to a Datomic database" do
      subject.connect(@connection_options)
      subject.connection.should be_a(Datomic::Client)
    end

    it_behaves_like "persistence API" do
      let(:model_class) { Mouse }

      before do
        Diametric::Persistence::REST.connect(@connection_options)
        Diametric::Persistence::REST.create_schemas
      end
    end
  end

  context "simple queries for various types" do
    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "peacock-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
    end

    it_behaves_like "supports various types" do
      let(:model_class) { Peacock }

      before do
        Diametric::Persistence::REST.connect(@connection_options)
        Diametric::Persistence::REST.create_schemas
      end
    end
  end

  context "simple queries for carinality many" do
    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "your-words-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
    end

    it_behaves_like "supports cardinality many" do
      let(:model_class) { YourWords }

      before do
        Diametric::Persistence::REST.connect(@connection_options)
        Diametric::Persistence::REST.create_schemas
      end
    end
  end

  context "simple queries for has_one association" do
    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "box-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
    end

    it_behaves_like "supports has_one association" do
      let(:parent_class) { Box }
      let(:child_class) { Mouse }

      before do
        Diametric::Persistence::REST.connect(@connection_options)
        Diametric::Persistence::REST.create_schemas
      end
    end
  end

  context "simple queries for has_many association" do
    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "big-box-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
    end

    it_behaves_like "supporting has_many association" do
      let(:parent_class) { BigBox }
      let(:child_class) { Mouse }

      before do
        Diametric::Persistence::REST.connect(@connection_options)
        Diametric::Persistence::REST.create_schemas
      end
    end
  end
end
