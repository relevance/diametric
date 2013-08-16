require 'spec_helper'

describe Diametric::Config do
  before do
    Diametric::Config.configuration.clear
  end

  describe ".configuration" do
    it "is empty by default" do
      Diametric::Config.configuration.should have(0).options
    end
  end

  describe ".configured?" do
    it "is true if configuration is present" do
      Diametric::Config.configuration[:uri] = 'datomic:free://sample'
      Diametric::Config.should be_configured
    end

    it "is false if no configuration has been added" do
      Diametric::Config.should_not be_configured
    end
  end

  describe ".load_and_connect!" do
    let(:path) { "/path/to/diametric.yml" }
    let(:env) { :test }
    let(:settings) { {'uri' => 'diametric:free://test'} }

    it "loads settings from the environment" do
      Diametric::Config::Environment.should_receive(:load_yaml).with(path, env).and_return(settings)
      Diametric::Config.stub(:connect!)

      Diametric::Config.load_and_connect!(path, env)
    end

    it "sets the configuration" do
      Diametric::Config::Environment.stub(:load_yaml => settings)
      Diametric::Config.stub(:connect!)
      Diametric::Config.load_and_connect!(path, env)

      Diametric::Config.configuration.should == settings
    end

    it "connects" do
      Diametric::Config::Environment.stub(:load_yaml => settings)
      Diametric::Config.should_receive(:connect!).with(settings)

      Diametric::Config.load_and_connect!(path, env)
    end
  end

  describe ".connect!" do
    it "establishes a base connection" do
      settings = double
      Diametric::Persistence.should_receive(:establish_base_connection).with(settings)
      Diametric::Config.connect!(settings)
    end
  end
end
