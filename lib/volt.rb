require 'volt/volt/environment'
require 'volt/extra_core/extra_core'
require 'volt/reactive/computation'
require 'volt/reactive/dependency'
require 'volt/utils/modes'
require 'volt/utils/volt_user_error'
require 'volt/utils/boolean_patch'
require 'volt/utils/time_patch'

require 'volt/config'
require 'volt/data_stores/data_store' unless RUBY_PLATFORM == 'opal'
require 'volt/volt/users'

module Volt
  @in_browser = if RUBY_PLATFORM == 'opal'
                  # When testing with opal-rspec, it technically is in a browser
                  # but its not setup with our own app code.
                  `!!document && !window.OPAL_SPEC_PHANTOM && window.$`
                else
                  false
                end

  include Modes

  class << self
    def root
      fail 'Volt.root can not be called from the client.' if self.client?
      @root ||= File.expand_path(Dir.pwd)
    end

    attr_writer :root

    def server?
      !!ENV['SERVER']
    end

    def client?
      !ENV['SERVER']
    end

    def source_maps?
      if !ENV['MAPS']
        # If no MAPS is specified, enable it in dev
        Volt.env.development?
      else
        ENV['MAPS'] != 'false'
      end
    end

    def env
      @env ||= Volt::Environment.new
    end

    def logger
      @logger ||= Volt::VoltLogger.new
    end

    attr_writer :logger

    def in_browser?
      @in_browser
    end

    # When we use something like a Task, we don't specify an app, so we use
    # a thread local or global to lookup the current app.  This lets us run
    # more than one app at once, giving deference to a global app.
    def current_app
      Thread.current['volt_app'] || $volt_app
    end

    # Runs code in the context of this app.
    def in_app
      previous_app = Thread.current['volt_app']
      Thread.current['volt_app'] = self

      begin
        yield
      ensure
        Thread.current['volt_app'] = previous_app
      end
    end
  end
end
