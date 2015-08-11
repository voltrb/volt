require 'sprockets-helpers'

module Volt
  class SprocketsHelpersSetup
    def initialize(env)
      # Configure Sprockets::Helpers (if necessary)
      Sprockets::Helpers.configure do |config|
        config.environment = env
        config.prefix      = '/assets'
        config.digest      = false
        config.public_path = 'public'

        # Force to debug mode in development mode
        # Debug mode automatically sets
        # expand = true, digest = false, manifest = false
        config.debug       = true if Volt.env.development?
      end
    end
  end
end