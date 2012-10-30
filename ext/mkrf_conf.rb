require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'
begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end
inst = Gem::DependencyInstaller.new
begin
  if RUBY_ENGINE == 'jruby'
    inst.install 'bundler'
    inst.install 'jbundler'
    $stderr.puts "Installing Datomic from Maven..."
    $stderr.flush
    system "jbundle install"
  end
rescue
  exit(1)
end

f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write <<EOF
task :default do
end
EOF
f.close
