# The following setup handles setting up the app on the server.
unless RUBY_PLATFORM == 'opal'
  require 'volt/server/message_bus/peer_to_peer'
end

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
          @live_query_pool = LiveQueryPool.new(@database, self)
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
            bus_name = Volt.config.message_bus.try(:bus_name) || 'peer_to_peer'
            begin
              message_bus_class = MessageBus.const_get(bus_name.camelize)
            rescue NameError => e
              raise "message bus name #{bus_name} was not found, be sure its "
                    + "gem is included in the gemfile."
            end

            @message_bus = message_bus_class.new(self)

            Thread.new do
              # Handle incoming messages in a new thread
              @message_bus.subscribe('volt_collection_update') do |collection_name|
                # update a collection, don't resend since we're coming from
                # the message bus.
                live_query_pool.updated_collection(collection_name, nil, true)
              end
            end
          end
        end
      end
    end
  end
end