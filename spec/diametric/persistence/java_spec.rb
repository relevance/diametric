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
    attribute :age, Integer
  end

  let(:db_uri) { 'datomic:mem://hello' }

  it "can connect to a Datomic database" do
    subject.connect(db_uri)
    subject.connection.should be_a(Java::DatomicPeer::LocalConnection)
  end

  it_behaves_like "persistence API" do
    let(:model_class) { Rat }

    before(:all) do
      subject.connect(db_uri)
      Diametric::Persistence::Java.create_schemas
    end
  end
end
