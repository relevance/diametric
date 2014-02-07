require 'rspec'

if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  require 'lock_jar'
  jar_file = File.join(File.dirname(__FILE__), "..", "Jarfile")
  lock_file = File.join(File.dirname(__FILE__), "..", "Jarfile.lock")
  LockJar.lock(jar_file)
  LockJar.install(lock_file)
  LockJar.load(lock_file)
end
require 'diametric'
require 'diametric/rest_service'
require 'diametric/transactor'
Dir["./spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |c|
#  c.fail_fast = true

  c.filter_run_excluding :integration => true unless ENV['INTEGRATION']
  c.filter_run_excluding :jruby => (not is_jruby?)
  c.filter_run_excluding :service => true unless ENV['RESTSERVICE']
  c.filter_run_excluding :transactor => true unless ENV['TRANSACTOR']

  c.filter_run_including :focused => true
  c.alias_example_to :fit, :focused => true

  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.before(:suite) do
    unless ENV['RESTSERVICE']
      @rest = Diametric::RestService.new("spec/test_version_file.yml", "tmp/datomic")
      @rest.start(:port => 46291, :db_alias => @storage, :uri => "datomic:mem://")
      PID = @rest.pid
    end
    if ENV['TRANSACTOR']
      FileUtils.cp(File.join('spec', 'config', 'logback.xml'), File.join('bin', 'logback.xml'))
    end
  end

  c.after(:suite) do
    Diametric::Persistence::Peer.shutdown(true) if is_jruby?
    unless ENV['RESTSERVICE']
      Process.kill("HUP", PID)
    end
    if ENV['TRANSACTOR']
      FileUtils.rm(File.join('bin', 'logback.xml'), :force => true)
    end
  end
end

RSpec::Matchers.define :be_an_equivalent_hash do |expected|
  match do |actual|
    status = true
    expected.keys.each do |k|
      next if k == :"db/id"
      status = false if actual[k].nil?
      status = false unless actual[k] == expected[k]
    end
    status
  end
end

RSpec::Matchers.define :be_an_equivalent_array do |expected|
  match do |actual|
    status = true
    expected.each_with_index do |e, index|
      next if e.kind_of?(String) && (e.gsub(/ /, "") == "#db/id[:db.part/user]")
      status = false unless actual[index] == e
    end
    status
  end
end

shared_examples "ActiveModel" do |model|
  require 'test/unit/assertions'
  require 'active_model/lint'
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  active_model_lints = ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/)

  let(:model) { subject }

  active_model_lints.each do |test_name|
    it "#{test_name.sub(/^test_/, '')}" do
      send(test_name)
    end
  end
end
