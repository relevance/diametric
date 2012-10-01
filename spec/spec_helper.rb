require 'rspec'
require 'diametric'

RSpec.configure do |c|
  c.fail_fast = true
  c.filter_run_including :focused => true
  c.alias_example_to :fit, :focused => true
  c.run_all_when_everything_filtered = true
  c.treat_symbols_as_metadata_keys_with_true_values = true
end
