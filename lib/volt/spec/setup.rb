class Volt
  def self.spec_setup(app_path='.')
    if ENV['BROWSER']
      if RUBY_PLATFORM == 'opal'
      else
        require 'capybara'
        require 'capybara/dsl'
        require 'capybara/rspec'
        require 'capybara/poltergeist'
      end
    end

    require 'volt'

    if ENV['BROWSER']
      if RUBY_PLATFORM == 'opal'
      else

        require 'volt/server'

        Capybara.server do |app, port|
          require 'rack/handler/thin'
          Rack::Handler::Thin.run(app, :Port => port)
        end

        Capybara.app = Server.new(app_path).app

        if ENV['BROWSER'] == 'phantom'
          Capybara.default_driver = :poltergeist
        elsif ENV['BROWSER'] == 'chrome'
          Capybara.register_driver :chrome do |app|
            Capybara::Selenium::Driver.new(app, :browser => :chrome)
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
            Capybara::Selenium::Driver.new(app, :browser => :safari)
          end
          Capybara.default_driver = :safari
        end
      end
    end

  end
end