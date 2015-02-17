module Volt
  class PhoneNumberValidator < FormatValidator
    DEFAULT_OPTIONS = {
      with: /^(\+?\d{1,2}[\.\-\ ]?\d{3}|\(\d{3}\)|\d{3})[\.\-\ ]?\d{3,4}[\.\-\ ]?\d{4}$/,
      message: 'must be a phone number with area or country code'
    }

    private

    def default_options
      DEFAULT_OPTIONS
    end
  end
end
