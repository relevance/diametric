require 'spec_helper'
require 'net/http'

describe Diametric::Transactor, :transactor =>true do
  let(:transactor) { Diametric::Transactor }

  before do
    dir = File.join(File.dirname(__FILE__), "../..", "tmp/datomic")
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
  end

  it "should find a class" do
    transactor.should be_true
  end

  it "should find a default conf file" do
    transactor.datomic_conf_file?.should be_true
  end

  it "should find a specified conf file" do
    transactor.datomic_conf_file?("spec/test_version_file.cnf").should be_true
  end

  it "should return false for version no" do
    transactor.datomic_conf_file?("datomic-free-0.8.3848").should be_false
  end

  it "should know datomic version specified" do
    transactor.datomic_version("spec/test_version_file.cnf").should == "datomic-free-0.8.3848"
    transactor.datomic_version("datomic-free-0.8.3848").should == "datomic-free-0.8.3848"
  end

  it  "should know the specified version of datomic has been downloaded" do
    transactor.downloaded?("spec/test_version_file.cnf", "tmp/datomic").should be_false
    transactor.downloaded?("datomic-free-0.8.3848", "tmp/datomic").should be_false

    transactor.download("spec/test_version_file.cnf", "tmp/datomic")
  
    transactor.downloaded?("spec/test_version_file.cnf", "tmp/datomic").should be_true
    transactor.downloaded?("datomic-free-0.8.3848", "tmp/datomic").should be_true
  end

  context Diametric::Transactor do
    let(:transactor) { Diametric::Transactor.new("spec/test_version_file.cnf", "tmp/datomic") }
    
    it "should start and stop transactor" do
      filename = File.join(File.dirname(__FILE__), "..", "config", "free-transactor-template.properties")
      File.exists?(filename).should be_true
      transactor.start(filename).should be_true
      transactor.stop
    end
  end

  context Diametric::Transactor do
    let(:transactor) { Diametric::Transactor.new("spec/test_version_file.cnf", "tmp/datomic") }

    it "should be available to create_database and connect to" do
      filename = File.join(File.dirname(__FILE__), "..", "config", "free-transactor-template.properties")
      transactor.start(filename).should be_true
      uri = "datomic:free://localhost:39082/transactor-#{SecureRandom.uuid}"
      Diametric::Persistence::Peer.create_database(uri).should be_true
      Diametric::Persistence::Peer.connect(uri).should be_true
      transactor.stop
    end
  end

end
