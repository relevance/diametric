shared_examples "persistence API" do
  describe "an instance" do
    let(:model) { model_class.new }

    it "can save" do
      # TODO deal correctly with nil values
      model.name = "Wilbur"
      model.age = 2
      model.save.should be_true
      model.should be_persisted
    end

    it "does not transact if nothing is changed" do
      model = model_class.new
      model.should_not be_changed
      model.save.should be_true
      model.should_not be_persisted
    end

    it "does not transact if invalid" do
      model.stub(:valid? => false)
      model.save.should be_false
    end

    describe '#update_attributes' do
      it "saves and updates values" do
        model = model_class.new(:name => "Stu").tap(&:save)
        new_values = { :name => "Stuart" }
        model.should_receive(:assign_attributes).with(new_values)
        model.save.should be_true
        model.name.should == "Stuart"
      end
    end

    describe "#assign_attributes" do
      it "updates attribute values" do
        model.assign_attributes(:name => "Stuart")
        model.name.should == "Stuart"
      end

      it "raises when trying to update unknown attributes" do
        expect { model.assign_attributes(:foo => :bar) }.to raise_error
      end
    end

    context "that is saved in Datomic" do
      before(:each) do
        model.name = "Wilbur"
        model.age = 2
        model.save
      end

      it "can find it by dbid" do
        model2 = model_class.get(model.dbid)
        model2.should_not be_nil
        model2.name.should == model.name
        model2.should == model
      end

      it "can save it back to Datomic with changes" do
        model.name = "Mr. Wilbur"
        model.save.should be_true

        model2 = model_class.get(model.dbid)
        model2.name.should == "Mr. Wilbur"
      end

      it "can find it by attribute" do
        model2 = model_class.first(:name => "Wilbur")
        model2.should_not be_nil
        model2.dbid.should == model.dbid
        model2.should == model
      end

      it "can find all matching conditions" do
        mice = model_class.where(:name => "Wilbur").where(:age => 2).all
        mice.should == [model]
      end

      it "can filter entities" do
        mice = model_class.filter(:<, :age, 3).all
        mice.should == [model]

        mice = model_class.filter(:>, :age, 3).all
        mice.should == []
      end

      it "can find all" do
        model_class.new(:name => "Smith", :age => 5).save
        mice = model_class.all
        mice.size.should == 2
        names = ["Smith", "Wilbur"]
        mice.each do |m|
          names.include?(m.name).should be_true
          names.delete(m.name).should == m.name
        end
        names.size.should == 0
      end
    end
  end
end
