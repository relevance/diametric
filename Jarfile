# -*- ruby -*-
repository 'http://clojars.org/repo/'
repository 'https://repository.jboss.org/nexus/content/groups/public/'
repository 'http://files.couchbase.com/maven2/'

if ENV["DATOMIC_VERSION_PATH"] &&
   !ENV["DATOMIC_VERSION_PATH"].empty?
   File.exists?(ENV["DATOMIC_VERSION_PATH"])
   datomic_version_path = ENV["DATOMIC_VERSION_PATH"]
else
   datomic_version_path = File.join(File.dirname(__FILE__), "datomic_version.yml")
end

require 'yaml'
datomic_versions = YAML.load(File.read(datomic_version_path))

if ENV['DIAMETRIC_ENV'] && (ENV['DIAMETRIC_ENV'] == "pro")
  artifactId = "datomic-pro"
  datomic_version = datomic_versions["pro"]
else
  artifactId = "datomic-free"
  datomic_version = datomic_versions["free"]
end

group :default, :runtime do
  jar "com.datomic:#{artifactId}:#{datomic_version}"
end
