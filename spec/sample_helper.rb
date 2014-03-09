require 'rspec'

begin
  require 'diametric'
rescue LoadError
  $:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
  require 'diametric'
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.run_all_when_everything_filtered = true
  c.filter_run_excluding :jruby => (not is_jruby?)
  c.filter_run_including :focused => true
  c.alias_example_to :fit, :focused => true
  c.order = 'default'

  c.after(:suite) do
    Diametric::Persistence::Peer.shutdown(true) if is_jruby?
  end
end
