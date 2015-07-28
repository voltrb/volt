require 'volt/volt/core' if RUBY_PLATFORM != 'opal'

module Volt
  class << self
    def spec_setup(app_path = '.')
      require 'volt'

      ENV['SERVER'] = 'true'
      ENV['VOLT_ENV'] = 'test'

      require 'volt/boot'

      # Create a main volt app for tests
      volt_app = Volt.boot(app_path)

      unless RUBY_PLATFORM == 'opal'
        begin
          require 'volt/spec/capybara'

          setup_capybara(app_path, volt_app)
        rescue LoadError => e
          Volt.logger.warn("unable to load capybara, if you wish to use it for tests, be sure it is in the app's Gemfile")
          Volt.logger.error(e)
        end
      end

      unless ENV['BROWSER']
        # Not running integration tests with ENV['BROWSER']
        RSpec.configuration.filter_run_excluding type: :feature
      end

      cleanup_db = -> do
        volt_app.database.drop_database

        # Clear cached for a reset
        volt_app.instance_variable_set('@store', nil)
        volt_app.reset_query_pool!
      end

      if RUBY_PLATFORM != 'opal'
        # Call once during setup to clear if we killed the last run
        cleanup_db.call
      end

      # Run everything in the context of this app
      Thread.current['volt_app'] = volt_app

      # Setup the spec collection accessors
      # RSpec.shared_context "volt collections", {} do
      RSpec.shared_context 'volt collections', {} do
        # Page conflicts with capybara's page method, so we call it the_page for now.
        # TODO: we need a better solution for page

        let(:the_page) { Model.new }
        let(:store) do
          @__store_accessed = true
          volt_app.store
        end
        let(:volt_app) { volt_app }
        let(:params) { volt_app.params }

        after do
          # Clear params if used
          url = volt_app.url
          if url.instance_variable_get('@params')
            url.instance_variable_set('@params', nil)
          end
        end

        if RUBY_PLATFORM != 'opal'
          after do |example|
            if @__store_accessed || example.metadata[:type] == :feature
              # Clear the database after each spec where we use store
              cleanup_db.call
            end
          end

          # Cleanup after integration tests also.
          before(:example, {type: :feature}) do
            @__store_accessed = true
          end
        end
      end
    end
  end
end
