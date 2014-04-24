require 'spec_helper'

describe Diametric::Bucket, :integration => true do
  context Rat do
    it_behaves_like "bucket API" do
      let(:model_class) { Rat }
    end
  end

  context Mouse do
    it_behaves_like "bucket API" do
      let(:model_class) { Mouse }
    end
  end
end
