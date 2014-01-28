shared_examples "supports has_one association" do
  describe "entity instance" do
    let(:parent) { parent_class.new }
    let(:child) { child_class.new }

    it "can save child" do
      # similar to thing.pet_id = pet.id; pet.save
      # diametric does pet.save; thing.pet = pet.dbid
      child.name = "Sophia"
      child.age = 5
      parent.pet = child

      child.should be_persisted
      child.dbid.to_i.should > 0
      child.class.all.first.name.should == "Sophia"
    end

    it "can save parent" do
      child.name = "Jacob"
      child.age = 3
      parent.pet = child
      parent.save

      parent.should be_persisted
      parent.dbid.to_i.should > 0
      searched_child = parent.class.all.first.pet
      searched_child.name.should == "Jacob"
      searched_child.age.should == 3
    end
  end
end
