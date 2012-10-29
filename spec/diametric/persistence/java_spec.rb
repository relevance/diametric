require 'spec_helper'

if RUBY_ENGINE == 'jruby'
  require 'diametric/persistence/java'

  class Mouse
    include Diametric::Entity
    include Diametric::Persistence::Java

    attribute :name, String, :index => true
  end
end

describe Diametric::Persistence::Java, :java do
  it "can create a Datomic database" do
    res = Diametric::Persistence::Java.create_database('datomic:mem://hello')
    res.should be_true
  end

  context "with a Datomic database" do
    let(:db_uri) { 'datomic:mem://hello' }

    before do
      subject.create_database(db_uri)
    end

    it "can connect to a Datomic database" do
      subject.connect(db_uri)
      subject.connection.should be_a(Java::DatomicPeer::LocalConnection)
    end
  end

  describe "an instance" do
    let(:mouse) { Mouse.new }
    let(:db_uri) { 'datomic:mem://hello' }

    before(:all) do
      subject.create_database(db_uri)
      subject.transact(Mouse.schema)
    end

    it "can save" do
      mouse.name = "Wilbur"
      mouse.save.should be_true
      mouse.should be_persisted
    end
  end
end
