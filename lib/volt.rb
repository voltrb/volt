require 'volt/volt/environment'
require 'volt/extra_core/extra_core'
require 'volt/reactive/computation'
require 'volt/reactive/dependency'
require 'volt/utils/modes'
require 'volt/utils/volt_user_error'

require 'volt/config'
unless RUBY_PLATFORM == 'opal'
  require 'volt/data_stores/data_store'
end
require 'volt/volt/users'

module Volt
  puts 'initializing volt'
  @in_browser = if RUBY_PLATFORM == 'opal'
                  `!!document && !window.OPAL_SPEC_PHANTOM`
                else
                  false
                end

  include Modes

  class << self
    def root
      # if running inside of a rails app we add the directory voltage otherwise the root is current directory
      # however it looks like we can actually get rid of this, since the server will initialize this for us
      @root ||= File.expand_path("#{Dir.pwd}#{VOLT_PATH if defined? VOLT_PATH }")
      #@root ||= File.expand_path(Dir.pwd)
    end

    attr_writer :root

    def server?
      !!ENV['SERVER']
    end

    def client?
      !ENV['SERVER']
    end

    def source_maps?
      !!ENV['MAPS']
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
  end
end
