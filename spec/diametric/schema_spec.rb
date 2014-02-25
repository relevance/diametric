require 'spec_helper'

describe Diametric::Entity, :integration => true, :jruby => true do
  context Rat do # Peer
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"rat/name",
         :"db/valueType"=>:"db.type/string",
         :"db/index"=>true},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"rat/age",
         :"db/valueType"=>:"db.type/long"}]
    }

    before do
      datomic_uri = "datomic:mem://rat-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "should generate a schema" do
      Rat.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Rat.create_schema(@conn).get }.
        not_to raise_exception
    end
  end

  context Mouse do # REST
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"mouse/name",
         :"db/valueType"=>:"db.type/string",
         :"db/index"=>true},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"mouse/age",
         :"db/valueType"=>:"db.type/long"}]
    }

    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "mouse-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
    end

    it "it should generate a schema" do
      Mouse.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Diametric::Persistence::REST.create_schemas }.
        not_to raise_exception
    end
  end

  context ScarletMacaw do # Peer
    let (:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/name",
         :"db/valueType"=>:"db.type/string"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/description",
         :"db/valueType"=>:"db.type/string",
         :"db/fulltext"=>true},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/talkative",
         :"db/valueType"=>:"db.type/boolean"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/colors",
         :"db/valueType"=>:"db.type/long"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/average_speed",
         :"db/valueType"=>:"db.type/double"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/observed",
         :"db/valueType"=>:"db.type/instant"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/case_no",
         :"db/valueType"=>:"db.type/uuid",
         :"db/index"=>true},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"scarlet_macaw/serial",
         :"db/valueType"=>:"db.type/uuid",
         :"db/unique"=>:"db.unique/value"}]
    }

    before do
      datomic_uri = "datomic:mem://scarlet-macaw-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "should generate a schema" do
      ScarletMacaw.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { ScarletMacaw.create_schema(@conn).get }.
        not_to raise_exception
      dbid = Diametric::Persistence::Peer.q("[:find ?e :in $ ?value :where [?e :db/ident ?value]]", @conn.db, ":scarlet_macaw/serial").first.first
      entity_fn = Java::ClojureLang::RT.var("datomic.api", "entity")
      emap = entity_fn.invoke(@conn.db.to_java, dbid)
      emap.get(":db/ident").to_s.should == ":scarlet_macaw/serial"
      emap.get(":db/cardinality").to_s.should == ":db.cardinality/one"
      emap.get(":db/valueType").to_s.should == ":db.type/uuid"
      emap.get(":db/unique").to_s.should == ":db.unique/value"
    end
  end

  context Peacock do # REST
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/name",
         :"db/valueType"=>:"db.type/string"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/description",
         :"db/valueType"=>:"db.type/string",
         :"db/fulltext"=>true},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/talkative",
         :"db/valueType"=>:"db.type/boolean"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/colors",
         :"db/valueType"=>:"db.type/long"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/average_speed",
         :"db/valueType"=>:"db.type/double"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/observed",
         :"db/valueType"=>:"db.type/instant"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/case_no",
         :"db/valueType"=>:"db.type/uuid",
         :"db/index"=>true},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"peacock/serial",
         :"db/valueType"=>:"db.type/uuid",
         :"db/unique"=>:"db.unique/value"}]
    }

    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "peacock-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
    end

    it "it should generate a schema" do
      Peacock.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Diametric::Persistence::REST.create_schemas }.
        not_to raise_exception
    end
  end

  context MyWords do # Peer
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/many",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"my_words/words",
         :"db/valueType"=>:"db.type/string"}]
    }

    before do
      datomic_uri = "datomic:mem://my-words-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "should genemywordse a schema" do
      MyWords.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { MyWords.create_schema(@conn).get }.
        not_to raise_exception
      dbid = Diametric::Persistence::Peer.q("[:find ?e :in $ ?value :where [?e :db/ident ?value]]", @conn.db, ":my_words/words").first.first
      entity_fn = Java::ClojureLang::RT.var("datomic.api", "entity")
      emap = entity_fn.invoke(@conn.db.to_java, dbid)
      emap.get(":db/ident").to_s.should == ":my_words/words"
      emap.get(":db/cardinality").to_s.should == ":db.cardinality/many"
      emap.get(":db/valueType").to_s.should == ":db.type/string"
    end
  end

  context YourWords do # REST
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/many",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"your_words/words",
         :"db/valueType"=>:"db.type/string"}]
    }

    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "your-words-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
    end

    it "it should generate a schema" do
      YourWords.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Diametric::Persistence::REST.create_schemas }.
        not_to raise_exception
    end
  end

  context Cage do # Peer
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"cage/pet",
         :"db/valueType"=>:"db.type/ref"}]
    }

    before do
      datomic_uri = "datomic:mem://cage-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "should genemywordse a schema" do
      Cage.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Cage.create_schema(@conn).get }.
        not_to raise_exception
      dbid = Diametric::Persistence::Peer.q("[:find ?e :in $ ?value :where [?e :db/ident ?value]]", @conn.db, ":cage/pet").first.first
      entity_fn = Java::ClojureLang::RT.var("datomic.api", "entity")
      emap = entity_fn.invoke(@conn.db.to_java, dbid)
      emap.get(":db/ident").to_s.should == ":cage/pet"
      emap.get(":db/cardinality").to_s.should == ":db.cardinality/one"
      emap.get(":db/valueType").to_s.should == ":db.type/ref"
    end
  end

  context Box do # REST
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"box/pet",
         :"db/valueType"=>:"db.type/ref"}]
    }

    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "box-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
    end

    it "it should generate a schema" do
      Box.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Diametric::Persistence::REST.create_schemas }.
        not_to raise_exception
    end
  end

  context Author do # Peer
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"author/name",
         :"db/valueType"=>:"db.type/string"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/many",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"author/books",
         :"db/valueType"=>:"db.type/ref"}]
    }

    before do
      datomic_uri = "datomic:mem://author-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "should genemywordse a schema" do
      Author.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Author.create_schema(@conn).get }.
        not_to raise_exception
      dbid = Diametric::Persistence::Peer.q("[:find ?e :in $ ?value :where [?e :db/ident ?value]]", @conn.db, ":author/books").first.first
      entity_fn = Java::ClojureLang::RT.var("datomic.api", "entity")
      emap = entity_fn.invoke(@conn.db.to_java, dbid)
      emap.get(":db/ident").to_s.should == ":author/books"
      emap.get(":db/cardinality").to_s.should == ":db.cardinality/many"
      emap.get(":db/valueType").to_s.should == ":db.type/ref"
    end
  end

  context Writer do # REST
    let(:expected) {
      [{:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"writer/name",
         :"db/valueType"=>:"db.type/string"},
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/many",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"writer/books",
         :"db/valueType"=>:"db.type/ref"}]
    }

    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "writer-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
    end

    it "it should generate a schema" do
      Writer.schema.each do |e|
        e.should be_an_equivalent_hash(expected.shift)
      end
    end

    it "should create schema" do
      expect { Diametric::Persistence::REST.create_schemas }.
        not_to raise_exception
    end
  end

  context Role do # Peer
    let(:expected) {
      [
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"role/type",
         :"db/valueType"=>:"db.type/ref"},
       [:"db/add", "#db/id [:db.part/user]", :"db/ident", :"role.type/accountant"],
       [:"db/add", "#db/id [:db.part/user]", :"db/ident", :"role.type/manager"],
       [:"db/add", "#db/id [:db.part/user]", :"db/ident", :"role.type/developer"]
      ]
    }

    before do
      datomic_uri = "datomic:mem://role-#{SecureRandom.uuid}"
      @conn = Diametric::Persistence::Peer.connect(datomic_uri)
    end

    after do
      @conn.release
    end

    it "should genemywordse a schema" do
      Role.schema.each do |e|
        if e.kind_of? Hash
          e.should be_an_equivalent_hash(expected.shift)
        elsif e.kind_of? Array
          e.should be_an_equivalent_array(expected.shift)
        end
      end
    end

    it "should create schema" do
      expect { Role.create_schema(@conn).get }.
        not_to raise_exception
      dbid = Diametric::Persistence::Peer.q("[:find ?e :in $ ?value :where [?e :db/ident ?value]]", @conn.db, ":role.type/accountant").first.first
      entity_fn = Java::ClojureLang::RT.var("datomic.api", "entity")
      emap = entity_fn.invoke(@conn.db.to_java, dbid)
      emap.get(":db/ident").to_s.should == ":role.type/accountant"
    end
  end

  context Position do # REST
    let(:expected) {
      [
       {:"db/id"=>"#db/id [:db.part/db]",
         :"db/cardinality"=>:"db.cardinality/one",
         :"db.install/_attribute"=>:"db.part/db",
         :"db/ident"=>:"position/type",
         :"db/valueType"=>:"db.type/ref"},
       [:"db/add", "#db/id [:db.part/user]", :"db/ident", :"position.type/accountant"],
       [:"db/add", "#db/id [:db.part/user]", :"db/ident", :"position.type/manager"],
       [:"db/add", "#db/id [:db.part/user]", :"db/ident", :"position.type/developer"]
      ]
    }

    before do
      @db_uri = ENV['DATOMIC_URI'] || 'http://localhost:46291'
      @storage = ENV['DATOMIC_STORAGE'] || 'free'
      @dbname = ENV['DATOMIC_NAME'] || "position-#{SecureRandom.uuid}"
      @connection_options = {
        :uri => @db_uri,
        :storage => @storage,
        :database => @dbname
      }
      Diametric::Persistence::REST.connect(@connection_options)
    end

    it "it should generate a schema" do
      Position.schema.each do |e|
        if e.kind_of? Hash
          e.should be_an_equivalent_hash(expected.shift)
        elsif e.kind_of? Array
          e.should be_an_equivalent_array(expected.shift)
        end
      end
    end

    it "should create schema" do
      expect { Diametric::Persistence::REST.create_schemas }.
        not_to raise_exception
    end
  end
end
