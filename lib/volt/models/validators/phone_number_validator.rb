module Volt
  class PhoneNumberValidator
    DEFAULT_OPTIONS = {
      with: /^(\+?\d{1,2}[\.\-\ ]?\d{3}|\(\d{3}\)|\d{3})[\.\-\ ]?\d{3,4}[\.\-\ ]?\d{4}$/,
      message: 'must be a phone number with area or country code'
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
