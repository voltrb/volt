module Volt
  class EmailValidator < FormatValidator
    DEFAULT_OPTIONS = {
      with: /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i,
      message: 'must be an email address'
    }

    private

    def default_options
      DEFAULT_OPTIONS
    end
  end
end
