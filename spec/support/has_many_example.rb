shared_examples "supports has_many association" do
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
  end
end
