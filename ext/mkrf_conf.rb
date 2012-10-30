begin
  if RUBY_ENGINE == 'jruby'
    require 'lock_jar'

    # get jarfile relative the gem dir
    lockfile = File.expand_path( "../../Jarfile.lock", __FILE__ )

    LockJar.install(lockfile)
  end
rescue
  exit(1)
end

f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write <<EOF
task :default
EOF
f.close
