# require 'volt/models/validations/errors'
require 'volt/models/validators/length_validator'
require 'volt/models/validators/presence_validator'

# Include in any class to get validation logic
module Validations
  module ClassMethods
    def validate(field_name, options)
      @validations ||= {}
      @validations[field_name] = options
    end

    def validations
      @validations
    end
  end

  def self.included(base)
    base.send :extend, ClassMethods
  end

  # Once a field is ready, we can use include_in_errors! to start
  # showing its errors.
  def mark_field!(field_name, trigger_changed=true)
    marked_fields[field_name] = true
  end

  def marked_fields
    @marked_fields ||= ReactiveHash.new
  end

  def marked_errors
    errors(true)
  end

  # TODO: Errors is being called for any validation change.  We should have errors return a
  # hash like object that only calls the validation for each one.
  def errors(marked_only=false)
    errors = {}

    validations = self.class.validations

    if validations
      # Merge into errors, combining any error arrays
      merge = Proc.new do |new_errors|
        errors.merge!(new_errors) do |key, new_val, old_val|
          new_val + old_val
        end
      end

      # Run through each validation
      validations.each_pair do |field_name, options|
        if marked_only
          # When marked only, skip any validations on non-marked fields
          next unless marked_fields[field_name]
        end

        options.each_pair do |validation, args|
          # Call the specific validator, then merge the results back
          # into one large errors hash.
          klass = validation_class(validation, args)

          if klass
            validate_with(merge, klass, field_name, args)
          else
            raise "validation type #{validation} is not specified."
          end
        end
      end
    end

    return errors
  end

  private
    # calls the validate method on the class, passing the right arguments.
    def validate_with(merge, klass, field_name, args)
      return merge.call(klass.validate(self, field_name, args))
    end

    def validation_class(validation, args)
      begin
        Object.const_get(:"#{validation.camelize}Validator")
      rescue NameError => e
        puts "Unable to find #{validation} validator"
      end
    end
end
