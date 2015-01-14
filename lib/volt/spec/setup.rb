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
        require 'volt/spec/capybara'

        setup_capybara(app_path)
      end
    end
  end
end
