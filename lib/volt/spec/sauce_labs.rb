module Volt
  class << self
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