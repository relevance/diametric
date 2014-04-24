require 'spec_helper'

describe Diametric::Bucket, :integration => true do
  it_behaves_like "bucket API" do
    let(:model_class) { Rat }
  end

  it_behaves_like "bucket API" do
    let(:model_class) { Mouse }
  end
end
