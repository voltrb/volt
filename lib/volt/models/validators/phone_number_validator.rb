module Volt
  class PhoneNumberValidator
    DEFAULT_REGEX = /^(\+?\d{1,2}[\.\-\ ]?\d{3}|\(\d{3}\)|\d{3})[\.\-\ ]?\d{3,4}[\.\-\ ]?\d{4}$/
    ERROR_MESSAGE = 'must be a phone number with area or country code'

    def self.validate(model, field_name, options)
      new(model, field_name, options).errors
    end

    def initialize(model, field_name, options)
      @value = model.read_attribute field_name

      case options
      when Hash, true, false
        configure options
      else
        fail 'arguments can only be a Boolean or a Hash'
      end
    end

    def valid?
      return false unless @value.is_a? String

      !!@value.match(@custom_regex || DEFAULT_REGEX)
    end

    def errors
      valid? ? {} : { phone_number: [ @custom_message || ERROR_MESSAGE ] }
    end

    private

    def configure(options)
      return unless options.is_a? Hash

      @custom_message = options.fetch(:error_message) { nil }
      @custom_regex = options.fetch(:with) { nil }
    end
  end
end
