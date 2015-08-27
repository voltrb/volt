# The following setup handles setting up the app on the server.
unless RUBY_PLATFORM == 'opal'
  require 'volt/server/message_bus/peer_to_peer'
  require 'volt/server/middleware/middleware_stack'
  require 'volt/server/middleware/default_middleware_stack'
  require 'volt/volt/core'

end

module Volt
  module ServerSetup
    module App
      def setup_paths
        # Load component paths
        @component_paths = ComponentPaths.new(@app_path)
        @component_paths.require_in_components(self)
      end

      def load_app_code
        setup_router
        require_http_controllers
      end

      def setup_router
        @router = Routes.new
      end

      def setup_preboot_middleware
        @middleware = MiddlewareStack.new
        DefaultMiddlewareStack.preboot_setup(self, @middleware)
      end

      def setup_postboot_middleware
        DefaultMiddlewareStack.postboot_setup(self, @middleware)
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

      # This config needs to run earlier than others
      def run_config
        path = "#{Volt.root}/config/app.rb"
        require(path) if File.exists?(path)
      end

      # Load in all .rb files in the initializers folders and the config/app.rb
      # file.
      def run_app_and_initializers
        files = []

        # Include the root initializers
        files += Dir[Volt.root + '/config/initializers/*.rb']
        files += Dir[Volt.root + '/config/initializers/server/*.rb']

        # Get initializers for each component
        #component_paths.app_folders do |app_folder|
        #  files += Dir["#{app_folder}/*/config/initializers/*.rb"]
        #  files += Dir["#{app_folder}/*/config/initializers/server/*.rb"]
        #end

        files.each do |initializer|
          require(initializer)
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
        return if ENV['NO_MESSAGE_BUS']

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