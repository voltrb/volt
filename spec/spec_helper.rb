require 'volt/spec/setup'

unless RUBY_PLATFORM == 'opal'
  require 'pry-byebug'
  # Specs are run against the kitchen sink app
  kitchen_sink_path = File.expand_path(File.join(File.dirname(__FILE__), 'apps/kitchen_sink'))
  Volt.spec_setup(kitchen_sink_path)

  RSpec.configure do |config|
    # config.before(:each) do
    #   DataStore.new.drop_database
    # end

    config.run_all_when_everything_filtered = true
    config.filter_run :focus

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = 'random'
    # config.seed = '31241'
  end
end
