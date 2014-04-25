shared_examples "bucket API" do
  describe "with entity class and data" do
    let(:bucket) { Diametric::Bucket.new }

    it "builds entity data" do
      sally = bucket.build(model_class, {name: "Sally", age: 5})
      /-\d+/.match(sally.to_s).should_not be_nil
      name_key = (model_class.prefix + "/name").to_sym
      age_key = (model_class.prefix + "/age").to_sym
      bucket[sally][name_key].should == "Sally"
      bucket[sally][age_key].should == 5
    end

    it "builds parent-child association data" do
      child = bucket.build(model_class, {name: "Tom", age: 7})
      parent = bucket.build(parent_class, {pet: child})
      name_key = (model_class.prefix + "/name").to_sym
      age_key = (model_class.prefix + "/age").to_sym
      pet_key = (parent_class.prefix + "/pet").to_sym
      bucket[parent][pet_key].should == child
      bucket.tx_data[0].should be_an_equivalent_hash({name_key => "Tom", age_key => 7})
      bucket.tx_data[1].has_key?(pet_key).should be_true
    end

    it "transact multiple data at once" do
      child = bucket.build(model_class, {name: "Will", age: 10})
      bucket.build(parent_class, {pet: child})
      child = bucket.build(model_class, {name: "Zac", age: 12})
      bucket.build(parent_class, {pet: child})
      child = bucket.build(model_class, {name: "Alice", age: 14})
      bucket.build(parent_class, {pet: child})
      bucket.count.should == 6
      bucket.save(@conn)
      bucket.count.should == 0
      model_class.all.size.should == 3
      parent_class.all.size.should == 3
      parent_class.all.collect(&:pet).collect(&:name).should =~ ["Will", "Zac", "Alice"]
    end
  end
end
