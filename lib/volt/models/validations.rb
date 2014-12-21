# require 'volt/models/validations/errors'
require 'volt/models/validators/email_validator'
require 'volt/models/validators/format_validator'
require 'volt/models/validators/length_validator'
require 'volt/models/validators/numericality_validator'
require 'volt/models/validators/phone_number_validator'
require 'volt/models/validators/presence_validator'
require 'volt/models/validators/unique_validator'

module Volt
  # Include in any class to get validation logic
  module Validations
    module ClassMethods
      def validate(field_name = nil, options = nil, &block)
        if block
          if field_name || options
            fail 'validate should be passed a field name and options or a block, not both.'
          end
          self.custom_validations ||= []
          custom_validations << block
        else
          self.validations             ||= {}
          validations[field_name] = options
        end
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
      base.class_attribute(:custom_validations, :validations)
    end

    # Once a field is ready, we can use include_in_errors! to start
    # showing its errors.
    def mark_field!(field_name)
      marked_fields[field_name] = true
    end

    def marked_fields
      @marked_fields ||= ReactiveHash.new
    end

    # Marks all fields, useful for when a model saves.
    def mark_all_fields!
      validations = self.class.validations
      if validations
        validations.each_key do |key|
          mark_field!(key.to_sym)
        end
      end
    end

    def marked_errors
      errors(true)
    end

    # server errors are errors that come back from the server when we save!
    # Any changes to the associated fields will clear the error until another
    # save!
    def server_errors
      @server_errors ||= ReactiveHash.new
    end

    # When a field is changed, we want to clear any errors from the server
    def clear_server_errors(key)
      @server_errors.delete(key)
    end

    # TODO: Errors is being called for any validation change.  We should have errors return a
    # hash like object that only calls the validation for each one.
    def errors(marked_only = false)
      errors = {}

      # Merge into errors, combining any error arrays
      merge = proc do |new_errors|
        errors.merge!(new_errors) do |key, new_val, old_val|
          new_val + old_val
        end
      end

      # Get the previous model from the buffer
      save_to = options[:save_to]
      if save_to && save_to.is_a?(Volt::Model)
        old_model = save_to
      else
        old_model = nil
      end

      errors = run_validations(errors, merge, marked_only, old_model)

      # See if any server errors are in place and merge them in if they are
      if Volt.client?
        errors = merge.call(server_errors.to_h)
      end

      errors = run_custom_validations(errors, merge, old_model)

      errors
    end

    private

    # Runs through each of the normal validations.
    def run_validations(errors, merge, marked_only, old_model)
      validations = self.class.validations
      if validations

        # Run through each validation
        validations.each_pair do |field_name, options|
          # When marked only, skip any validations on non-marked fields
          next if marked_only && !marked_fields[field_name]

          options.each_pair do |validation, args|
            # Call the specific validator, then merge the results back
            # into one large errors hash.
            klass = validation_class(validation, args)

            if klass
              validate_with(merge, klass, old_model, field_name, args)
            else
              fail "validation type #{validation} is not specified."
            end
          end
        end
      end

      errors
    end

    def run_custom_validations(errors, merge, old_model)
      # Call all of the custom validations
      custom_validations = self.class.custom_validations
      if custom_validations
        custom_validations.each do |custom_validation|
          # Run the validator in the context of the model, passes in
          # the old_model as an argument
          result = instance_exec(old_model, &custom_validation)

          if result
            errors = merge.call(result)
          end
        end
      end

      errors
    end

    # calls the validate method on the class, passing the right arguments.
    def validate_with(merge, klass, old_model, field_name, args)
      merge.call(klass.validate(self, old_model, field_name, args))
    end

    def validation_class(validation, args)
      Volt.const_get(:"#{validation.camelize}Validator")
    rescue NameError => e
      puts "Unable to find #{validation} validator"
    end
  end
end
