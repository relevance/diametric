repository 'http://clojars.org/repo/'
repository 'https://repository.jboss.org/nexus/content/groups/public/'
repository 'http://files.couchbase.com/maven2/'

datomic_names = File.read(File.join(File.dirname(__FILE__), "datomic_version.yml"))
require 'yaml'
datomic_versions = YAML.load(datomic_names)

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
