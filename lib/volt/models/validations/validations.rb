# require 'volt/models/validations/errors'
require 'volt/models/validations/length'

# Include in any class to get validation logic
module Validations
  module ClassMethods
    def validate(field_name, options)
      @@validations ||= {}
      @@validations[field_name] = options
    end
  end

  def self.included(base)
    base.send :extend, ClassMethods
  end

  def errors
    errors = {}

    # Merge into errors, combining any error arrays
    merge = Proc.new do |new_errors|
      errors.merge!(new_errors) do |key, new_val, old_val|
        new_val + old_val
      end
    end

    if defined?(@@validations)
      @@validations.each_pair do |field_name, options|
        options.each_pair do |validation, args|
          case validation
          when :length
            merge.call(Length.validate(self, field_name, args))
          end
        end
      end
    end

    return errors
  end
end