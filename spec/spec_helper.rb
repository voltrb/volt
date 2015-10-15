
require 'volt/spec/setup'

unless RUBY_PLATFORM == 'opal'
  begin
    require 'rack/test'
    require 'pry-byebug'
  rescue LoadError => e
    # Ignore if not installed
  end
  require 'coveralls'
  Coveralls.wear!

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    add_filter 'spec/'

    # all Opal / Front end stuff.
    add_filter 'lib/volt/page/bindings'
    add_filter 'lib/volt/page/document_events'
    add_filter 'lib/volt/page/targets/dom_template'
    add_filter 'lib/volt/utils/local_storage'
    add_filter 'lib/volt/benchmark'

    # Copied in from opal until 0.8 comes out.
    add_filter 'lib/volt/utils/promise'

    # Copied in from concurrent-ruby, waiting for gem release
    add_filter 'lib/volt/utils/read_write_lock.rb'
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
    config.seed = '10780'
  end

end
