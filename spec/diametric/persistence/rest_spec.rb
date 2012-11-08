require 'spec_helper'
require 'diametric/persistence/rest'

describe Diametric::Persistence::REST, :integration do
  class Mouse
    include Diametric::Entity
    include Diametric::Persistence::REST

    attribute :name, String, :index => true
    attribute :age, Integer
  end

  let(:db_uri) { ENV['DATOMIC_URI'] || 'http://localhost:9000' }
  let(:storage) { ENV['DATOMIC_STORAGE'] || 'test' }
  let(:dbname) { ENV['DATOMIC_NAME'] || "test-#{Time.now.to_i}" }

  it "can connect to a Datomic database" do
    subject.connect(db_uri, storage, dbname)
    subject.connection.should be_a(Datomic::Client)
    puts "connect"
  end

  it_behaves_like "persistence API" do
    let(:model_class) { Mouse }

    before(:all) do
      subject.connect(db_uri, storage, dbname)
      Diametric::Persistence::REST.create_schemas
    end
  end

  it "should get all" do
    puts "all"
  end
end
