require 'spec_helper'
require 'net/http'

describe Diametric::RestService, :service =>true do
  let(:service) { Diametric::RestService }

  before (:all) {
    dir = File.join(File.dirname(__FILE__), "../..", "tmp/datomic")
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
  }

  it "should find a class" do
    service.should be_true
  end

  it "should find a default conf file" do
    service.datomic_conf_file?.should be_true
  end

  it "should find a specified conf file" do
    service.datomic_conf_file?("spec/test_version_file.cnf").should be_true
  end

  it "should return false for version no" do
    service.datomic_conf_file?("datomic-free-0.8.3848").should be_false
  end

  it "should know datomic version specified" do
    service.datomic_version("spec/test_version_file.cnf").should == "datomic-free-0.8.3848"
    service.datomic_version("datomic-free-0.8.3848").should == "datomic-free-0.8.3848"
  end

  it  "should know the specified version of datomic has been downloaded" do
    service.downloaded?("spec/test_version_file.cnf", "tmp/datomic").should be_false
    service.downloaded?("datomic-free-0.8.3848", "tmp/datomic").should be_false

    service.download("spec/test_version_file.cnf", "tmp/datomic")
  
    service.downloaded?("spec/test_version_file.cnf", "tmp/datomic").should be_true
    service.downloaded?("datomic-free-0.8.3848", "tmp/datomic").should be_true
  end

  context Diametric::RestService do
    let(:rest) { Diametric::RestService.new("spec/test_version_file.cnf", "tmp/datomic") }
    
    it "should start and stop rest service" do
      uri = URI("http://localhost:46921")
      expect { Net::HTTP.get_response(uri) }.to raise_error
      rest.start(:port => 46921, :db_alias => "free", :uri => "datomic:mem://")
      expect { Net::HTTP.get_response(uri) }.not_to raise_error
      rest.stop
      expect { Net::HTTP.get_response(uri) }.to raise_error
    end
  end
end
