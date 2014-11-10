require 'volt/spec/sauce_labs'

module Volt
  class << self
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
  end
end