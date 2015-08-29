require 'volt/models/errors'
require 'volt/models/validators/format_validator'
require 'volt/models/validators/email_validator'
require 'volt/models/validators/inclusion_validator'
require 'volt/models/validators/length_validator'
require 'volt/models/validators/numericality_validator'
require 'volt/models/validators/phone_number_validator'
require 'volt/models/validators/presence_validator'
require 'volt/models/validators/unique_validator'
require 'volt/models/validators/type_validator'

module Volt
  # Include in any class to get validation logic
  module Validations
    module ClassMethods
      # Validate is called directly on the class and sets up the validation to be run
      # each time validate! is called on the class.
      def validate(field_name = nil, options = nil, &block)
        if block
          if field_name || options
            fail 'validate should be passed a field name and options or a block, not both.'
          end
          self.custom_validations ||= []
          custom_validations << block
        else
          self.validations_to_run ||= {}
          validations_to_run[field_name] ||= {}
          validations_to_run[field_name].merge!(options)
        end
      end

      # Validations takes a block, and can contain validate calls inside of it
      # which will conditionally be run based on the code in the block.  The
      # context of the block will be the current model.
      def validations(*run_in_actions, &block)
        unless block_given?
          raise 'validations must take a block, use `validate` to setup a validation on a class directly.'
        end

        # Add a validation block to run during each validation
        validate do
          action = new? ? :create : :update

          if run_in_actions.size == 0 || run_in_actions.include?(action)
            @instance_validations = {}
            @instance_custom_validations = []

            instance_exec(action, &block)

            result = run_validations(@instance_validations)
            result.merge!(run_custom_validations(@instance_custom_validations))

            @instance_validations = nil
            @instance_custom_validations = nil

            result
          end
        end
      end
    end

    # Called on the model inside of a validations block.  Allows the user to
    # control if validations should be run.
    def validate(field_name = nil, options = nil, &block)
      if block
        # Setup a custom validation inside of the current validations block.
        if field_name || options
          fail 'validate should be passed a field name and options or a block, not both.'
        end
        @instance_custom_validations << block
      else
        @instance_validations[field_name] ||= {}
        @instance_validations[field_name].merge!(options)
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
      base.class_attribute(:custom_validations, :validations_to_run)
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
      # TODO: We can use a Set here, but set was having issues.  Check in a
      # later version of opal.
      fields_to_mark = []

      # Look at each validation
      validations = self.class.validations_to_run
      if validations
        fields_to_mark += validations.keys
      end

      # Also include any current fields
      fields_to_mark += attributes.keys

      fields_to_mark.each do |key|
        mark_field!(key.to_sym)
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

    def errors(marked_only = false)
      @errors ||= Errors.new

      if marked_only
        # Only return the fields that have been marked
        @errors.to_h.select { |key, _| marked_fields[key] }
      else
        @errors
      end
    end

    # TODO: Errors is being called for any validation change.  We should have errors return a
    # hash like object that only calls the validation for each one.
    def validate!
      errors.clear

      # Run the before_validate callbacks
      run_callbacks(:before_validate).then do
        # Run the actual validations
        run_validations
      end.then do
        # See if any server errors are in place and merge them in if they are
        errors.merge!(server_errors.to_h) if Volt.client?
      end.then do
        run_custom_validations
      end.then do
        # Return the errors object
        errors
      end
    end

    # Returns true if any of the changed fields now has an error
    # @return [Boolean] true if one of the changed fields has an error.
    def error_in_changed_attributes?
      errs = errors

      changed_attributes.each_pair do |key, _|
        # If any of the fields with errors are also the ones that were
        return true if errs[key]
      end

      false
    end

    private

    # Runs through each of the normal validations.
    # @param [Array] An array of validations to run
    # @return [Promise] a promsie to run all validations
    def run_validations(validations = nil)
      # Default to running the class level validations
      validations ||= self.class.validations_to_run

      promise = Promise.new.resolve(nil)
      if validations

        # Run through each validation
        validations.each_pair do |field_name, options|
          promise = promise.then { run_validation(field_name, options) }
        end
      end

      promise
    end

    # Runs an individual validation
    # @returns [Promise]
    def run_validation(field_name, options)
      promise = Promise.new.resolve(nil)
      options.each_pair do |validation, args|
        # Call the specific validator, then merge the results back
        # into one large errors hash.
        klass = validation_class(validation, args)

        if klass
          # Chain on the promises
          promise = promise.then do
            klass.validate(self, field_name, args)
          end.then do |errs|
            errors.merge!(errs)
          end
        else
          fail "validation type #{validation} is not specified."
        end
      end

      promise
    end

    def run_custom_validations(custom_validations = nil)
      # Default to running the class level custom validations
      custom_validations ||= self.class.custom_validations

      promise = Promise.new.resolve(nil)

      if custom_validations
        custom_validations.each do |custom_validation|
          # Add to the promise chain
          promise = promise.then do
            # Run the validator in the context of the model
            instance_exec(&custom_validation)
          end.then do |errs|
            errors.merge!(errs)
          end
        end
      end

      promise
    end

    def validation_class(validation, args)
      Volt.const_get(:"#{validation.camelize}Validator")
    rescue NameError => e
      Volt.logger.error "Unable to find #{validation} validator"
    end
  end
end
