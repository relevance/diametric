require 'spec_helper'
require 'diametric/entity'

require 'rspec/expectations'

describe Diametric::Entity do
  describe "in a class" do
    subject { Person }

    it { should respond_to(:attribute) }
    it { should respond_to(:schema) }
    it { should respond_to(:from_query) }

    it "should generate a schema" do
      expected = [
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/index" => true,
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/email",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/many",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/birthday",
          :"db/valueType" => :"db.type/instant",
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/awesome",
          :"db/valueType" => :"db.type/boolean",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "Is this person awesome?",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/ssn",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/value",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/secret_name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/identity",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/bio",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/fulltext" => true,
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/middle_name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/nicknames",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/many",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/parent",
          :"db/valueType" => :"db.type/ref",
          :"db/cardinality" => :"db.cardinality/many",
          :"db/doc" => "A person's parent",
          :"db.install/_attribute" => :"db.part/db" }
      ]
      Person.schema.each do |s|
        s.should == expected.shift
      end
    end
  end

  describe "in an instance" do
    subject { Person.new }
    let(:model) { Person.new }

    it_should_behave_like "ActiveModel"

    it { should respond_to(:tx_data) }

    it "should handle attributes correctly" do
      subject.name.should be_nil
      subject.name = "Clinton"
      subject.name.should == "Clinton"
    end
    
    it "should return attribute names" do
      subject.attribute_names.should eql(Person.attribute_names)
    end
    
    it "should return a hash of attributes" do
      attributes = subject.attributes
      
      attributes.should be_a Hash
      attributes.keys.should eql(subject.attribute_names)
      attributes[:middle_name].should eql("Danger")
    end
    
    it "should raise a validation error" do
      expect { Robin.new.save! }.to raise_error(Diametric::Errors::ValidationError)
    end

  end

  describe ".new" do
    it "should work without arguments" do
      Person.new.should be_a(Person)
    end

    it "should assign attributes based off argument keys" do
      person = Person.new(:name => "Dashiell D", :secret_name => "Monito")
      person.name.should == "Dashiell D"
      person.secret_name.should == "Monito"
    end

    it "should defaults attributes" do
      Person.new.middle_name.should == "Danger"
    end

    it "should transform default arrays into sets" do
      Person.new.nicknames.should == Set.new(["Buddy", "Pal"])
    end
  end

  describe ".from_query" do
    it "should assign dbid and attributes" do
      goat = Goat.from_query([1, "Beans", DateTime.parse("1976/9/4")])
      goat.dbid.should == 1
      goat.name.should == "Beans"
      goat.birthday.should == DateTime.parse("1976/9/4")
    end
  end

  describe "#tx_data" do
    context "for an entity with cardinality/many attributes" do

      let(:entity_class) do
        gen_entity_class(named = "test") do
          attribute :many, String, :cardinality => :many
        end
      end

      describe "with a dbid" do
        it "should generate a protraction tx for added entries" do
          entity = entity_class.new(:many => %w|foo bar|)
          entity.many.should == Set["foo", "bar"]
          entity.dbid = 1
          entity.tx_data.should == [[:"db/add", 1, :"test/many", ["foo", "bar"]]]
        end

        it "should generate a retraction tx for removed entries" do
          entity = entity_class.new
          entity.dbid = 1
          entity.instance_variable_set(:"@changed_attributes", { 'many' => Set["original", "unchanged"]})
          entity.many = Set["unchanged", "new"]
          entity.tx_data.should == [
            [:"db/retract", 1, :"test/many", ["original"]],
            [:"db/add", 1, :"test/many", ["new"]]
          ]
        end
      end

      describe "without a db/id" do
        it "should generate a protraction tx" do
          entity = entity_class.new(:many => %w|foo bar|)
          tx = entity.tx_data.first
          tx.should =~ [:"db/add", entity.send(:tempid), :"test/many", ['foo', 'bar']]
        end
      end
    end

    context "for an entity with only cardinality/one attributes" do
      let(:goat) { Goat.new(:name => "Beans", :birthday => Date.parse("2002-04-15"))}

      describe "without a dbid" do
        it "should generate a transaction with a new tempid" do
          # Equivalence is currently wrong on EDN tagged values.
          tx = goat.tx_data.first
          tx.keys.should =~ [:"db/id", :"goat/name", :"goat/birthday"]
          tx[:"db/id"].to_edn.should match(%r"#db/id \[:db.part/user \-\d+\]")
          tx[:"goat/name"].should == "Beans"
          tx[:"goat/birthday"].should == goat.birthday
        end
      end

      describe "with a dbid" do
        it "should generate a transaction with the dbid" do
          goat.dbid = 1
          goat.tx_data.should == [
            { :"db/id" => 1,
              :"goat/name" => "Beans",
              :"goat/birthday" => goat.birthday
            }
          ]
        end

        it "should generate a transaction with only specified attributes" do
          goat.dbid = 1
          goat.tx_data(:name).should == [
            { :"db/id" => 1,
              :"goat/name" => "Beans"
            }
          ]
        end
      end

    end

  end

  context "boolean type" do
    subject { Choice }

    it "should generate a schema" do
      expected = [
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"choice/item",
                    :"db/valueType" => :"db.type/string",
                    :"db/cardinality" => :"db.cardinality/one",
                    :"db.install/_attribute" => :"db.part/db" },
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"choice/checked",
                    :"db/valueType" => :"db.type/boolean",
                    :"db/cardinality" => :"db.cardinality/one",
                    :"db.install/_attribute" => :"db.part/db" }
                 ]
      @created_schema = subject.schema
      expected.each do |e|
        @created_schema.shift.should be_an_equivalent_hash(e)
      end
    end
  end

  context "uuid type" do
    subject { Customer }

    it "should generate a schema" do
      expected = [
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"customer/name",
                    :"db/valueType" => :"db.type/string",
                    :"db/cardinality" => :"db.cardinality/one",
                    :"db.install/_attribute" => :"db.part/db" },
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"customer/id",
                    :"db/valueType" => :"db.type/uuid",
                    :"db/cardinality" => :"db.cardinality/one",
                    :"db.install/_attribute" => :"db.part/db" }
                 ]
      @created_schema = subject.schema
      expected.each do |e|
        @created_schema.shift.should be_an_equivalent_hash(e)
      end
    end
  end

  context "Float, Double type" do
    subject { Account }

    it "should generate a schema" do
      expected = [
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"account/name",
                    :"db/valueType" => :"db.type/string",
                    :"db/cardinality" => :"db.cardinality/one",
                    :"db.install/_attribute" => :"db.part/db" },
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"account/deposit",
                    :"db/valueType" => :"db.type/double",
                    :"db/cardinality" => :"db.cardinality/many",
                    :"db.install/_attribute" => :"db.part/db" },
                  { :"db/id" => subject.send(:tempid, :"db.part/db"),
                    :"db/ident" => :"account/amount",
                    :"db/valueType" => :"db.type/double",
                    :"db/cardinality" => :"db.cardinality/one",
                    :"db.install/_attribute" => :"db.part/db" }
                 ]
      @created_schema = subject.schema
      expected.each do |e|
        @created_schema.shift.should be_an_equivalent_hash(e)
      end
    end
  end

  context "community sample" do
    subject { Organization }

    it { should respond_to(:attribute) }
    it { should respond_to(:enum) }
    it { should respond_to(:schema) }

    it "should generate a schema" do
      expected = [
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"organization/name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/fulltext" => true,
          :"db/doc" => "A organization's name",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"organization/url",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "A organization's url",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"organization/neighborhood",
          :"db/valueType" => :"db.type/ref",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "A organization's neighborhood",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"organization/category",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/many",
          :"db/fulltext" => true,
          :"db/doc" => "All organization categories",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"organization/orgtype",
          :"db/valueType" => :"db.type/ref",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "A organization orgtype enum value",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"organization/type",
          :"db/valueType" => :"db.type/ref",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "A organization type enum value",
          :"db.install/_attribute" => :"db.part/db" },
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.orgtype/community" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.orgtype/commercial" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.orgtype/nonprofit"],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.orgtype/personal"],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/email-list"],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/twitter"],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/facebook-page" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/blog" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/website" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/wiki" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/myspace" ],
        [ :"db/add", subject.send(:tempid, :"db.part/user"), :"db/ident", :"organization.type/ning"]
      ]

      @created_schema = Organization.schema
      expected.each do |e|
        @created_schema.shift.should == e
      end
    end
  end


  context "seattle sample", :jruby do
    describe Diametric::Entity do
      subject { District }

      it "should create peer schema" do
        expected = [
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"district/name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/identity",
          :"db/doc" => "A unique district name (upsertable)",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => subject.send(:tempid, :"db.part/db"),
          :"db/ident" => :"district/region",
          :"db/valueType" => :"db.type/ref",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "A district region enum value",
          :"db.install/_attribute" => :"db.part/db" },
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/n"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/ne"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/e"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/se"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/s"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/sw"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/w"],
        [ :"db/add", "#db/id[:db.part/user]", :"db/ident", :"district.region/nw"]
      ]
        @created_schema = District.schema
        expected.each do |e|
          if e.is_a? Hash
            @created_schema.shift.should be_an_equivalent_hash(e)
          else
            @created_schema.shift.should be_an_equivalent_array(e)
          end
        end
      end
    end
  end
end
