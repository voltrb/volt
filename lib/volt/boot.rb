unless RUBY_PLATFORM == 'opal'
  # An option to skip requiring.
  unless ENV['SKIP_BUNDLER_REQUIRE']
    # Require in gems
    Bundler.require((ENV['VOLT_ENV'] || ENV['RACK_ENV'] || :development).to_sym)
  end
end

require 'volt/models'
require 'volt/server/rack/component_paths'

if RUBY_PLATFORM == 'opal'
  require 'volt'
else
  require 'volt/page/page'
end
require 'volt/volt/app'

module Volt
  def self.boot(app_path)
    # Boot the app
    App.new(app_path)
  end
end
