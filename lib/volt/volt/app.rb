require 'opal'

# On the server, setup the server env by default
unless RUBY_PLATFORM == 'opal'
  ENV['SERVER'] ||= 'true'
end

# on the client, we want to include the main volt.rb file
require 'volt'
require 'volt/models'
require 'volt/controllers/model_controller'
require 'volt/tasks/task'
require 'volt/page/bindings/bindings'
require 'volt/page/template_renderer'
require 'volt/page/string_template_renderer'
require 'volt/page/document_events'
require 'volt/page/sub_context'
require 'volt/page/targets/dom_target'
require 'volt/data_stores/base_adaptor_client'

if RUBY_PLATFORM == 'opal'
  require 'volt/page/channel'
else
  require 'volt/page/channel_stub'
end
require 'volt/router/routes'
require 'volt/models/url'
require 'volt/page/url_tracker'
require 'volt/benchmark/benchmark'
require 'volt/page/tasks'
require 'volt/volt/repos'
require 'volt/volt/templates'

if RUBY_PLATFORM == 'opal'
  require 'volt/volt/client_setup/browser'
else
  require 'volt/volt/server_setup/app'
  require 'volt/server/template_handlers/view_processor'
end

module Volt
  class App
    include Volt::Repos

    if RUBY_PLATFORM != 'opal'
      # Include server app setup
      include Volt::ServerSetup::App
    end

    attr_reader :component_paths, :router, :live_query_pool,
                :channel_live_queries, :app_path, :database, :message_bus,
                :middleware, :browser
    attr_accessor :sprockets, :opal_files

    def initialize(app_path=nil)
      app_path ||= Dir.pwd

      if Volt.server? && !app_path
        raise "Volt::App.new requires an app path to boot"
      end

      # Expand to a full path
      app_path = File.expand_path(app_path)

      @app_path = app_path
      $volt_app = self

      # Setup root path
      Volt.root = app_path

      if RUBY_PLATFORM == 'opal'
        setup_browser
      end

      if RUBY_PLATFORM != 'opal'
        # We need to run the root config first so we can setup the Rack::Session
        # middleware.
        run_config

        # Setup all of the middleware we can before we load the users components
        # since the users components might want to add middleware during boot.
        setup_preboot_middleware

        # Setup all app paths
        setup_paths

        # Require in app and initializers
        run_app_and_initializers unless RUBY_PLATFORM == 'opal'

        require_components

        # abort_on_exception is a useful debugging tool, and in my opinion something
        # you probbaly want on.  That said you can disable it if you need.
        unless RUBY_PLATFORM == 'opal'
          Thread.abort_on_exception = Volt.config.abort_on_exception
        end

        load_app_code

        # Load up the main component dependencies.  This is needed to load in
        # any opal_gem calls in dependencies.rb
        # TODO: Needs to support all components
        if Dir.exists?(Volt.root + '/app/main')
          AssetFiles.from_cache(app_url, 'main', component_paths)
        end

        reset_query_pool!

        # Setup the middleware that we can only setup after all components boot.
        setup_postboot_middleware

        setup_routes

        start_message_bus
      end
    end

    def templates
      @templates ||= Templates.new
    end

    # Called on the client side to add routes
    def add_routes(&block)
      @router ||= Routes.new
      @router.define(&block)
      url.router = @router
    end

    # Callled on the client to add store compiled templates
    def add_template(*args)
      templates.add_template(*args)
    end

    def tasks
      @tasks ||= Tasks.new(self)
    end

    def channel
      @channel ||= begin
        if Volt.client?
          Channel.new
        else
          ChannelStub.new
        end
      end
    end

    # Setup a Page instance.
    def setup_browser
      @browser = Browser.new(self)
    end
  end
end

if Volt.client?
  $volt_app = Volt::App.new

  `$(document).ready(function() {`
    $volt_app.browser.start
  `});`
end
