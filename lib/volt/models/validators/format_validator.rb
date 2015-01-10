module Volt
  class FormatValidator
    # Creates a new instance with the provided options and returns it's errors
    #
    # @note the second param +old_model+ is unused and will soon be removed,
    #   you can pass nil in the mean time
    #
    # @example
    #   options = { with: /.+@.+/, message: 'must include an @ symobl' }
    #
    #   FormatValidator.validate(user, nil, 'email', options)
    #
    # @example
    #   numbers_only = /^\d+$/
    #   sum_equals_ten = ->(s) { s.chars.map(&:to_i).reduce(:+) == 10 }
    #
    #   options = [
    #     { with: numbers_only, message: 'must include only numbers' },
    #     { with: sum_equals_ten, message: 'must add up to 10' }
    #   ]
    #
    #   FormatValidator.validate(user, nil, 'email', options)
    #
    # @param model [Volt::Model] the model being validated
    # @param old_model [NilClass] no longer used, will be removed
    # @param field_name [String] the name of the field being validated
    #
    # @param options (see #apply)
    # @option options (see #apply)
    #
    # @return (see #errors)
    def self.validate(model, old_model, field_name, options)
      new(model, field_name).apply(options).errors
    end

    # @param model [Volt::Model] the model being validated
    # @param field_name [String] the name of the field being validated
    def initialize(model, field_name)
      @name = field_name
      @value = model.read_attribute field_name
      @criteria = []
    end

    # Applies criteria to the validator in a variety of forms
    #
    # @see .validate param examples
    # @param options [Hash, Array<Hash>] criteria and related error messages
    #
    # @option options [Regexp, Proc] :with criterion for validation
    # @option options [String] :message to display if criterion not met
    #   - will be appended to the field name
    #   - should start with something like:
    #     - +"must include..."+
    #     - +"should end with..."+
    #     - +"is invalid because..."+
    #
    # @return [self] returns itself for chaining
    def apply(options)
      return apply_list options if options.is_a? Array
      with options[:with], options[:message]
      self
    end

    # Returns the first of the validation errors or an empty hash
    #
    # @return [Hash] hash of validation errors for the field
    #   - +{}+ if there are no errors
    #   - +{ field_name: [messages] }+ if there are errors
    def errors
      valid? ? {} : { @name => error_messages }
    end

    # Returns an array of validation error messages
    # @return [Array<String>]
    def error_messages
      @criteria.reduce([]) do |e, c|
        test(c[:criterion]) ? e : e << c[:message]
      end
    end

    # Returns true or false depending on if the model passes all its criteria
    # @return [Boolean]
    def valid?
      error_messages.empty?
    end

    # Adds a criterion and error message
    #
    # @param criterion [Regexp, Proc] criterion for validation
    # @param message [String] to display if criterion not met
    #   - will be appended to the field name
    #   - should start with something like:
    #     - +"must include..."+
    #     - +"should end with..."+
    #     - +"is invalid because..."+
    #
    # @return (see #apply)
    def with(criterion, message)
      @criteria << { criterion: criterion, message: message }
      self
    end

    private

    def apply_list(array)
      array.each { |options| apply options }
      self
    end

    def test(criterion)
      return false unless @value.respond_to? :match

      !!(criterion.try(:call, @value) || criterion.try(:match, @value))
    end
  end
end
