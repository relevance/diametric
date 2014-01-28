require 'spec_helper'

describe Diametric::Query do
  let(:query) { Diametric::Query.new(Goat) }

  describe "#where" do
    it "is non-destructive" do
      query.where(:age => 2)
      query.conditions.should be_empty
    end

    it "raises when non-searchable conditions (id?) are passed"
  end

  describe "#filter" do
    it "is non-destructive" do
      query.filter(:<, :age, 2)
      query.filters.should be_empty
    end
  end

  describe "#each" do
    it "collapses cardinality/many attribute results" do
      model = gen_entity_class :person do
        attribute :name, String
        attribute :likes, String, :cardinality => :many
      end
      model.stub(:q => [[1, "Stu", "chocolate"], [1, "Stu", "vanilla"]])
      model.should_receive(:from_query).with([1, "Stu", ["chocolate", "vanilla"]], nil, false)
      Diametric::Query.new(model, nil, false).each {|x| x}
    end
  end

  describe "#collapse_results" do
    let (:model) do
      gen_entity_class do
        attribute :name, String
        attribute :likes, String, :cardinality => :many
      end
    end
    let(:query) { Diametric::Query.new(model, nil, true) }

    context "with multiple results per entity" do
      it "collapses cardinality/many attributes into lists" do
        results = [[1, "Stu", "chocolate"], [1, "Stu", "vanilla"], [1, "Stu", "raspberry"]]
        collapsed = query.send(:collapse_results, results).first
        collapsed.should == [1, "Stu", ["chocolate", "vanilla", "raspberry"]]
      end
    end

    context "with single result per entity" do
      it "collapses cardinality/many attributes into lists" do
        results = [[1, "Stu", "chocolate"]]
        collapsed = query.send(:collapse_results, results).first
        collapsed.should == [1, "Stu", ["chocolate"]]
      end
    end
  end

  describe "#all" do
    it "returns set for values of cardinality/many" do
      model = gen_entity_class :person do
        attribute :name, String
        attribute :likes, String, :cardinality => :many
      end
      model.stub(:q => [[1, "Stu", "chocolate"], [1, "Stu", "vanilla"]])
      Diametric::Query.new(model, nil, false).all.each do |e|
        e.name.should == "Stu"
        e.likes.class.should == Set
        e.likes.should include "chocolate"
        e.likes.should include "vanilla"
      end
    end
  end

  describe "#data" do
    it "should generate a query given no conditions or filters" do
      query.data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :in, ~"\$",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        []
      ]
    end

    it "should generate a query given a condition" do
      query.where(:name => "Beans").data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :in, ~"\$", ~"?name",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        ["Beans"]
      ]
    end

    it "should generate a query given multiple conditions" do
      bday = DateTime.parse("2003-09-04 11:30 AM")

      query.where(:name => "Beans", :birthday => bday).data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :in, ~"\$", ~"?name", ~"?birthday",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        ["Beans", bday]
      ]
    end
  end
end
