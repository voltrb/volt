require 'volt/spec/sauce_labs'

module Volt
  class << self
    def setup_capybara(app_path, volt_app = nil)
      browser = ENV['BROWSER']

      if browser
        setup_capybara_app(app_path, volt_app)

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

    def setup_capybara_app(app_path, volt_app)
      require 'capybara'
      require 'capybara/dsl'
      require 'capybara/rspec'
      require 'capybara/poltergeist'
      require 'selenium-webdriver'
      require 'volt/server'

      case RUNNING_SERVER
      when 'thin'
        Capybara.server do |app, port|
          require 'rack/handler/thin'
          Rack::Handler::Thin.run(app, Port: port)
        end
      when 'puma'
        Capybara.server do |app, port|
          Puma::Server.new(app).tap do |s|
            s.add_tcp_listener Capybara.server_host, port
          end.run.join
        end
      end

      # Setup server, use existing booted app
      Capybara.app = Server.new(app_path, volt_app).app
    end
  end
end
