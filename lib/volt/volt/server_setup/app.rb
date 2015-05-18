# The following setup handles setting up the app on the server.

module Volt
  module ServerSetup
    module App
      def load_app_code
        # Load component paths
        @component_paths = ComponentPaths.new(@app_path)
        @component_paths.require_in_components(@page || $page)

        setup_router
        require_http_controllers
      end

      def setup_router
        # Find the route file
        home_path  = @component_paths.component_paths('main').first
        routes = File.read("#{home_path}/config/routes.rb")
        @router = Routes.new.define do
          eval(routes)
        end
      end

      def require_http_controllers
        @component_paths.app_folders do |app_folder|
          # Sort so we get consistent load order across platforms
          Dir["#{app_folder}/*/controllers/server/*.rb"].each do |ruby_file|
            # path = ruby_file.gsub(/^#{app_folder}\//, '')[0..-4]
            # require(path)
            require(ruby_file)
          end
        end
      end

      def reset_query_pool!
        if RUBY_PLATFORM != 'opal'
          # The load path isn't setup at the top of app.rb, so we wait to require
          require 'volt/tasks/live_query/live_query_pool'

          # Setup LiveQueryPool for the app
          @database = Volt::DataStore.fetch
          @live_query_pool = LiveQueryPool.new(@database)
          @channel_live_queries = {}
        end
      end

      def start_message_bus
        unless RUBY_PLATFORM == 'opal'

          # Don't run in test env, since you probably only have one set of tests
          # running at a time, and even if you have multiple, they shouldn't be
          # updating each other.
          unless Volt.env.test?
            # Start the message bus
            @message_bus = MessageBus.new(@page)

            Thread.new do
              # Handle incoming messages in a new thread
              @message_bus.on('message') do |message|
                cmd, msg = message.split('|')

                if cmd == 'u'
                  # update a collection

                end
                # puts "GOT MESSAGE: #{message.inspect}"
              end
            end
          end
        end
      end
    end
  end
end