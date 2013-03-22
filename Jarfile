repository 'http://clojars.org/repo/'
repository 'https://repository.jboss.org/nexus/content/groups/public/'

local_repo File.join(File.dirname(__FILE__), "repository")

datomic_name = File.read(File.join(File.dirname(__FILE__), "datomic_version.cnf"))
version = /(\d|\.)+/.match(datomic_name)[0]
datomic_name.slice!(version)
artifactId = datomic_name.chop

group :default, :runtime do
  jar "com.datomic:#{artifactId}:#{version}"
end
