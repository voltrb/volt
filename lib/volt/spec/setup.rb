module Volt
  class << self
    def spec_setup(app_path = '.')
      require 'volt'
      unless RUBY_PLATFORM == 'opal'
        ENV['SERVER'] = 'true'
        ENV['VOLT_ENV'] = 'test'

        require 'volt/boot'

        # Require in app
        Volt.boot(app_path)

        setup_capybara(app_path)
      end
    end

    def setup_capybara(app_path)
      browser = ENV['BROWSER']

      if browser
        setup_capybara_app(app_path)

        case browser
        when 'phantom'
          Capybara.default_driver = :poltergeist
        when 'chrome', 'safari'
          # Use the browser name, note that safari requires an extension to run
          browser = browser.to_sym
          Capybara.register_driver(browser) do |app|
            Capybara::Selenium::Driver.new(app, browser: browser)
          end

          Capybara.default_driver = browser
        when 'firefox'
          Capybara.default_driver = :selenium
        when 'sauce'
          setup_sauce_labs
        end
      end
    end

    def setup_capybara_app(app_path)
      require 'capybara'
      require 'capybara/dsl'
      require 'capybara/rspec'
      require 'capybara/poltergeist'
      require 'volt/server'

      Capybara.server do |app, port|
        require 'rack/handler/thin'
        Rack::Handler::Thin.run(app, Port: port)
      end

      Capybara.app = Server.new(app_path).app
    end

    def setup_sauce_labs
      require "sauce"
      require "sauce/capybara"

      Sauce.config do |c|
        if ENV['OS']
          # Use a specifc OS, BROWSER, VERSION combo (for travis)
          c[:browsers] = [
            [ENV['OS'], ENV['USE_BROWSER'], ENV['VERSION']]
          ]
        else
          # Run all
          c[:browsers] = [
            # ["Windows 7", "Chrome", "30"],
            # ["Windows 8", "Firefox", "28"],
            ["Windows 8.1", "Internet Explorer", "11"],
            ["Windows 8.0", "Internet Explorer", "10"],
            ["Windows 7.0", "Internet Explorer", "9"],
            # ["OSX 10.9", "iPhone", "8.1"],
            # ["OSX 10.8", "Safari", "6"],
            # ["Linux", "Chrome", "26"]
          ]
        end
        c[:start_local_application] = false
      end

      Capybara.default_driver = :sauce
      Capybara.javascript_driver = :sauce
    end
  end
end
