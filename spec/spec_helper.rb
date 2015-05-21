
require 'volt/spec/setup'

unless RUBY_PLATFORM == 'opal'
  require 'pry-byebug'
  require 'coveralls'
  Coveralls.wear!

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'lib/volt/page/bindings' # all Opal / Front end stuff.
  end
end

# Specs are run against the kitchen sink app
kitchen_sink_path = File.expand_path(File.join(File.dirname(__FILE__), 'apps/kitchen_sink'))
Volt.spec_setup(kitchen_sink_path)

unless RUBY_PLATFORM == 'opal'
  RSpec.configure do |config|
    config.run_all_when_everything_filtered = true
    config.filter_run :focus

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = 'random'
    config.seed = '61236'
  end

end
