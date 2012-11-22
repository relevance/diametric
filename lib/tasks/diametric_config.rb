# This rake task creates config/diametric.yml file.
# usage:
#   rake diametric:config[REST,dbname,port,storage] ;=> for REST connection
#   rake diametric:config[PEER,dbname]              ;=> for PEER connection
#   rake diametric:config[FREE,dbname,port]         ;=> for Free transactor connection
# examples:
#   rake diametric:config[REST,sample,9000,test]    ;=> for REST, bin/rest 9000 test datomic:mem://
#   rake diametric:config[PEER,sample]              ;=> for PEER
#   rake diametric:config[FREE,sample,4334]         ;=> for Free transactor
#
# note:
# For supporting pro version, perhaps, this should cover more configurations.
# refs: http://docs.datomic.com/clojure/index.html#datomic.api/connect

require 'rake'
namespace :diametric do
  desc "Generate config/diametric.yml"
  task :config, [:type, :database, :port, :storage] => [:environment] do |t, args|
    config = {"development" => {}}
    case args[:type]
      when "REST"
        config["development"]["uri"]=rest_uri(args)
        config["development"]["storage"]=args[:storage]
        config["development"]["database"]=args[:database]
      when "PEER"
        config["development"]["uri"]=peer_uri(args)
      when "FREE"
        config["development"]["uri"]=free_uri(args)
    end
    puts config.to_yaml
    File.open(File.join(Rails.root, "config", "diametric.yml"), "w").write(config.to_yaml)
  end
end

def rest_uri(args)
  ["http://localhost:", args[:port]].join
end

def peer_uri(args)
  ["datomic:mem://", args[:database]].join
end

def free_uri(args)
  ["datomic:free://localhost:", args[:port], "/", args[:database]].join
end