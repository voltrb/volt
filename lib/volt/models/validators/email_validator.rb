module Volt
  class EmailValidator
    DEFAULT_OPTIONS = {
      with: /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i,
      message: 'must be an email address'
    }

    def self.validate(model, old_model, field_name, options)
      new(model, field_name, options).errors
    end

    def self.new(model, field_name, options)
      options = DEFAULT_OPTIONS if options == true
      options = DEFAULT_OPTIONS.merge options

      FormatValidator.new(model, field_name).apply options
    end
  end
end
