module Volt
  class EmailValidator
    DEFAULT_REGEX = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i
    ERROR_MESSAGE = 'must be an email address'

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
      valid? ? {} : { email: [@custom_message || ERROR_MESSAGE] }
    end

    private

    def configure(options)
      return unless options.is_a? Hash

      @custom_message = options.fetch(:error_message) { nil }
      @custom_regex = options.fetch(:with) { nil }
    end
  end
end
