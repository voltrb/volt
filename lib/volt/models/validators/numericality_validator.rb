module Volt
  class NumericalityValidator
    def self.validate(model, field_name, args)
      # Construct the class and return the errors
      new(model, field_name, args).errors
    end

    attr_reader :errors

    def initialize(model, field_name, args)
      @field_name = field_name
      @args = args
      @errors = {}

      @value = model.get(field_name)

      # Convert to float if it is a string for a float
      # The nil check and the nan? check are only require for opal 0.6
      unless @value.nil?
        begin
          @value = Kernel.Float(@value)
        rescue ArgumentError => e
          @value = nil
        end
        # @value = nil if RUBY_PLATFORM == 'opal' && @value.nan?
      end

      check_errors
    end

    def add_error(error)
      field_errors = (@errors[@field_name] ||= [])
      field_errors << error
    end

    # Looks at the value
    def check_errors
      if @value && @value.is_a?(Numeric)
        if @args.is_a?(Hash)

          @args.each do |arg, val|
            case arg
            when :min
              Volt.logger.warn('numericality validator min: is deprecated in favor of gte:')
              add_error("number must be greater than #{val}") if @value < val
            when :max
              Volt.logger.warn('numericality validator max: is deprecated in favor of lte:')
              add_error("number must be less than #{val}") if @value > val
            when :gte
              add_error("number must be greater than or equal to #{val}") unless @value >= val
            when :lte
              add_error("number must be less than or equal to #{val}") unless @value <= val
            when :gt
              add_error("number must be greater than #{val}") unless @value > val
            when :lt
              add_error("number must be less than #{val}") unless @value < val
            end
          end

        end
      else
        message = (@args.is_a?(Hash) && @args[:message]) || 'must be a number'
        add_error(message)
      end
    end
  end
end
