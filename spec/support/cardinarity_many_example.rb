shared_examples "supports cardinality many" do
  describe "entity instance" do
    let(:model) { model_class.new }

    it "can save" do
      model.words = ["hopefully", "likely", "possibly"]
      model.save.should be_true
      model.should be_persisted

      model.class.all.first.words.should == Set.new(["hopefully", "likely", "possibly"])
    end

    describe "#assign_attributes" do
      let(:words) {
        model.words = ["sadlly", "happily", "joyfully"]
        model.save
        model
      }

      it "updates words" do
        new_values = { "words" => ["calmly", "peacefully", "joyfully"] }
        words.update_attributes(new_values)

        words.should_not be_changed
        words.words.should == Set.new(["calmly", "peacefully", "joyfully"])

        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:words => new_values["words"]}, nil, true).first
        else
          # not sure, but for some reason, REST likes singular.
          result = model_class.where({:word => new_values["words"]}).first
        end
        result.dbid.should == words.dbid
      end
    end
  end
end
