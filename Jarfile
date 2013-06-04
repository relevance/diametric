repository 'http://clojars.org/repo/'
repository 'https://repository.jboss.org/nexus/content/groups/public/'
repository 'http://files.couchbase.com/maven2/'

datomic_names = File.read(File.join(File.dirname(__FILE__), "datomic_version.cnf")).split
if ENV['DIAMETRIC_ENV'] && (ENV['DIAMETRIC_ENV'] == "pro")
  datomic_name = datomic_names[1]
else
  datomic_name = datomic_names[0]
end
version = /(\d|\.)+/.match(datomic_name)[0]
datomic_name.slice!(version)
artifactId = datomic_name.chop

group :default, :runtime do
  jar "com.datomic:#{artifactId}:#{version}"
end
