module Volt
  class << self
    def spec_setup(app_path = '.')
      require 'volt'

      ENV['SERVER'] = 'true'
      ENV['VOLT_ENV'] = 'test'

      require 'volt/boot'

      # Require in app
      Volt.boot(app_path)

      unless RUBY_PLATFORM == 'opal'
        begin
          require 'volt/spec/capybara'

          setup_capybara(app_path)
        rescue LoadError => e
          Volt.logger.warn("unable to load capybara, if you wish to use it for tests, be sure it is in the app's Gemfile")
          Volt.logger.error(e)
        end
      end

      unless ENV['BROWSER']
        # Not running integration tests with ENV['BROWSER']
        RSpec.configuration.filter_run_excluding :type => :feature
      end

      # Setup the spec collection accessors
      # RSpec.shared_context "volt collections", {} do
      RSpec.shared_examples_for 'volt collections', {} do
        # Page conflicts with capybara's page method, so we call it the_page for now.
        # TODO: we need a better solution for page

        let(:the_page) { Model.new }
        let(:store) do
          @__store_accessed = true
          $page ||= Page.new
          $page.store
        end

        after do
          if @__store_accessed
            # Clear the database after each spec where we use store
            # @@db ||= Volt::DataStore.fetch
            # @@db.drop_database
            ::DataStore.new.drop_database

            $page.instance_variable_set('@store', nil)
          end
        end
      end

    end
  end
end
