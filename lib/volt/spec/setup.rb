module Volt
  def self.spec_setup(app_path = '.')
    if RUBY_PLATFORM == 'opal'
      require 'volt'
    else
      ENV['SERVER'] = 'true'

      if ENV['BROWSER']
        require 'capybara'
        require 'capybara/dsl'
        require 'capybara/rspec'
        require 'capybara/poltergeist'
      end

      require 'volt'
      require 'volt/boot'

      # Require in app
      Volt.boot(Dir.pwd)

      if ENV['BROWSER']
        require 'volt/server'

        Capybara.server do |app, port|
          require 'rack/handler/thin'
-         Rack::Handler::Thin.run(app, Port: port)
        end

        Capybara.app = Server.new(app_path).app

        if ENV['BROWSER'] == 'phantom'
          Capybara.default_driver = :poltergeist
        elsif ENV['BROWSER'] == 'chrome'
          Capybara.register_driver :chrome do |app|
            Capybara::Selenium::Driver.new(app, browser: :chrome)
          end

          Capybara.default_driver = :chrome
        elsif ENV['BROWSER'] == 'firefox'

          # require 'selenium/webdriver'
          # # require 'selenium/client'
          #
          Capybara.default_driver = :selenium

          # Capybara.register_driver :selenium_firefox do |app|
          #   Capybara::Selenium::Driver.new(app, :browser => :firefox)
          # end
          # Capybara.current_driver = :selenium_firefox
        elsif ENV['BROWSER'] == 'safari'
          # Needs extension
          Capybara.register_driver :safari do |app|
            Capybara::Selenium::Driver.new(app, browser: :safari)
          end
          Capybara.default_driver = :safari
        elsif ENV['BROWSER'] == 'sauce'
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
  end
end
