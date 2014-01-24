require 'uuid'

shared_examples "supports various types" do
  describe "entity instance" do
    let(:model) { model_class.new }

    it "can save" do
      model.name = "Wilbur"
      model.description = "This bird has a lot of colors on its body which draws other animals' attentions"
      model.talkative = true
      model.colors = 200
      model.average_speed = 12.34
      model.observed = DateTime.parse("2013-12-24T07:18:29")
      # REST failes to save UUID
      if model_class.ancestors.include? Diametric::Persistence::Peer
        model.case_no = UUID.new.generate
        model.serial = UUID.new.generate
      end
      model.save.should be_true
      model.should be_persisted
    end

    describe '#update_attributes' do
      let(:bird) {
        model.name = "William"
        model.description = "This bird is famous for its colorful body."
        model.talkative = false
        model.colors = 150
        model.average_speed = 6.99
        model.observed = DateTime.parse("2010-11-12T05:16:27")
        # REST failes to save UUID
        if model_class.ancestors.include? Diametric::Persistence::Peer
          model.case_no = UUID.new.generate
          model.serial = UUID.new.generate
        end
        model.save
        model
      }

      it "saves and updates name" do
        new_values = { "name" => "Stuart" }
        bird.update_attributes(new_values)

        bird.should_not be_changed
        bird.name.should == "Stuart"
        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:name => new_values["name"]}, nil, true).first
        else
          result = model_class.where({:name => new_values["name"]}).first
        end
        result.dbid.should == model.dbid
      end

      it "saves and updates description" do
        new_values = { "description" => "Many words should be here to replace the value of description." }
        bird.update_attributes(new_values)

        bird.should_not be_changed
        bird.description.should include("Many words")
        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:description => new_values["description"]}, nil, true).first
        else
          result = model_class.where({:description => new_values["description"]}).first
        end
        result.dbid.should == model.dbid
      end

      it "saves and updates talkative" do
        new_values = { "talkative" => true }
        bird.update_attributes(new_values)

        bird.should_not be_changed
        bird.talkative.should be_true
        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:talkative => new_values["talkative"]}, nil, true).first
        else
          result = model_class.where({:talkative => new_values["talkative"]}).first
        end
        result.dbid.should == model.dbid
      end

      it "saves and updates colors" do
        new_values = { "colors" => 345 }
        bird.update_attributes(new_values)

        bird.should_not be_changed
        bird.colors.should be_true
        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:colors => new_values["colors"]}, nil, true).first
        else
          result = model_class.where({:colors => new_values["colors"]}).first
        end
        result.dbid.should == model.dbid
      end

      it "saves and updates average_speed" do
        new_values = { "average_speed" => 1.58 }
        bird.update_attributes(new_values)

        bird.should_not be_changed
        bird.average_speed.should be_true
        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:average_speed => new_values["average_speed"]}, nil, true).first
        else
          result = model_class.where({:average_speed => new_values["average_speed"]}).first
        end
        result.dbid.should == model.dbid
      end

      it "saves and updates observed" do
        new_values = { "observed" => DateTime.parse("2012-11-23T06:17:28") }
        bird.update_attributes(new_values)

        bird.should_not be_changed
        bird.observed.should be_true
        if model_class.ancestors.include? Diametric::Persistence::Peer
          result = model_class.where({:observed => new_values["observed"]}, nil, true).first
        else
          result = model_class.where({:observed => new_values["observed"]}).first
        end
        result.dbid.should == model.dbid
      end

      it "saves and updates case_no" do
        if model_class.ancestors.include? Diametric::Persistence::REST
          pending "REST fails to save UUID type"
        else
          no = UUID.new.generate
          new_values = { "case_no" => no }
          bird.update_attributes(new_values)

          bird.should_not be_changed
          bird.case_no.should be_true
          if model_class.ancestors.include? Diametric::Persistence::Peer
            result = model_class.where({:case_no => new_values["case_no"]}, nil, true).first
          else
            result = model_class.where({:case_no => new_values["case_no"]}).first
          end
          result.dbid.should == model.dbid
        end
      end

      it "saves and updates serial" do
        if model_class.ancestors.include? Diametric::Persistence::REST
          pending "REST fails to save UUID type"
        else
          no = UUID.new.generate
          new_values = { "serial" => no }
          bird.update_attributes(new_values)

          bird.should_not be_changed
          bird.serial.should be_true
          if model_class.ancestors.include? Diametric::Persistence::Peer
            result = model_class.where({:serial => new_values["serial"]}, nil, true).first
          else
            result = model_class.where({:serial => new_values["serial"]}).first
          end
          result.dbid.should == model.dbid
        end
      end
    end
  end
end
