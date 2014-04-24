shared_examples "bucket API" do
  describe "with entity class and data" do
    let(:bucket) { Diametric::Bucket.new }

    it "builds entity data" do
      sally = bucket.build(model_class, {name: "Sally", age: 5})
      /-\d+/.match(sally.to_s).should_not be_nil
      name_key = (model_class.prefix + "/name").to_sym
      age_key = (model_class.prefix + "/age").to_sym
      bucket[sally].should ==
        {name_key => "Sally", age_key => 5}
    end
  end
end
