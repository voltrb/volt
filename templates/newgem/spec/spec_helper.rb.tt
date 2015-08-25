# Volt sets up rspec and capybara for testing.
require 'volt/spec/setup'

# When testing Volt component gems, we boot up a dummy app first to run the
# test in, so we have access to Volt itself.
dummy_app_path = File.join(File.dirname(__FILE__), 'dummy')
Volt.spec_setup(dummy_app_path)

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
