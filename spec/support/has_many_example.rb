shared_examples "supporting has_many association" do
  describe "entity instance" do
    let(:parent) { parent_class.new }
    let(:child) { child_class.new }

    it "can save child" do
      child.name = "Emma"
      child.age = 15
      parent.pets << child

      child.should be_persisted
      child.dbid.to_i.should > 0
    end

    it "can save parent" do
      child.name = "Ethan"
      child.age = 14
      parent.pets << child
      parent.save

      parent.should be_persisted
      parent.dbid.to_i.should > 0
      searched_children = parent.class.first.pets
      searched_children.collect(&:name).should include "Ethan"
      searched_children.collect(&:age).should include 14
    end

    it "can find children" do
      child1 = child_class.new(name: "Michael", age: 10)
      parent.pets << child1
      child2 = child_class.new(name: "Mia", age: 9)
      parent.pets << child2
      parent.save

      searched_parent = parent.class.first
      searched_parent.pets.size.should == 2
      searched_parent.pets.collect(&:name).should =~ ["Michael", "Mia"]
      searched_parent.pets.collect(&:age).should =~ [10, 9]
      searched_parent.pets.empty?.should == false
    end

    it "can destory child" do
      child1 = child_class.new(name: "Alexander", age: 5)
      child2 = child_class.new(name: "Abigail", age: 6)
      parent.pets = [child1, child2]
      parent.save

      searched_parent = parent.class.first
      searched_parent.pets.size.should == 2

      searched_parent.pets.destroy(child1)
      searched_parent.pets.size.should == 1
      searched_parent.pets.collect(&:name).should == ["Abigail"]
      searched_parent.pets.collect(&:age).should == [6]

      searched_children = child_class.all
      searched_children.size.should == 1
      searched_children.first.dbid.should == child2.dbid
    end

    it "can delete child" do
      child1 = child_class.new(name: "Joseph", age: 1)
      child2 = child_class.new(name: "Janet", age: 2)
      parent.pets = [child1, child2]
      parent.save

      searched_parent = parent.class.first
      searched_parent.pets.size.should == 2

      searched_parent.pets.delete(child1, child2)
      searched_parent.pets.size.should == 0

      searched_children = child_class.all
      searched_children.size.should == 2
      searched_children.collect(&:name).should =~ ["Joseph", "Janet"]
      searched_children.collect(&:age).should =~ [1, 2]
    end
  end
end
