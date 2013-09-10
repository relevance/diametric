repository 'http://clojars.org/repo/'
repository 'https://repository.jboss.org/nexus/content/groups/public/'
repository 'http://files.couchbase.com/maven2/'

datomic_names = File.read(File.join(File.dirname(__FILE__), "datomic_version.yml"))
require 'yaml'
datomic_versions = YAML.load(datomic_names)

if ENV['DIAMETRIC_ENV'] && (ENV['DIAMETRIC_ENV'] == "pro")
  datomic_version = datomic_versions["pro"]
else
  datomic_version = datomic_versions["free"]
end
version = /(\d|\.)+/.match(datomic_version)[0]
datomic_version.slice!(version)
artifactId = datomic_version.chop

group :default, :runtime do
  jar "com.datomic:#{artifactId}:#{version}"
end
