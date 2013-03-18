require 'spec_helper'
require 'diametric/persistence/rest'

describe Diametric::Persistence::REST, :integration do
  class Mouse
    include Diametric::Entity
    include Diametric::Persistence::REST

    attribute :name, String, :index => true
    attribute :age, Integer
  end

  before(:all) do
    @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
    @storage = ENV['DATOMIC_STORAGE'] || 'free'
    @dbname = ENV['DATOMIC_NAME'] || "test-#{Time.now.to_i}"
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

    before(:all) do
      Diametric::Persistence::REST.connect(@connection_options)
      Diametric::Persistence::REST.create_schemas
    end
  end
end
