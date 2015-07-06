require 'volt/reactive/reactive_accessors'

module Volt
  module Buffer
    # Save saves the contents of a buffer to the save_to location.  If the buffer is new, it will create a new
    # model to save to.  Otherwise it will be an existing model.  Save returns a promise that may fail with
    # validation errors from the server (or the client).  You can also pass a block as a shortcut to calling
    # ```.save!.then do```
    def save!(&block)
      # TODO: this shouldn't need to be run, but if no attributes are assigned, then
      # if needs to be run.  Maybe there's a better way to handle it.
      validate!.then do
        # Get errors from validate
        errors = self.errors.to_h

        result = nil

        if errors.size == 0
          # cache save_to in a local
          save_to = self.save_to
          if save_to
            if save_to.is_a?(ArrayModel)
              # Add to the collection
              promise = save_to.create(attributes)
            else
              # We have a saved model
              promise = save_to.assign_attributes(attributes)
            end

            result = promise.then do |new_model|
              # The main model saved, so mark the buffer as not new
              @new = false

              if new_model
                # Mark the model as loaded
                new_model.change_state_to(:loaded_state, :loaded)

                # Set the buffer's id to track the main model's id
                self.save_to = new_model
              end

              # Copy attributes back from save_to model
              @attributes = new_model.attributes

              # Remove tracked changes
              clear_tracked_changes!

              new_model
            end.fail do |errors|
              if errors.is_a?(Hash)
                server_errors.replace(errors)

                # Merge the server errors into the main errors
                self.errors.merge!(server_errors.to_h)
              end

              promise_for_errors(errors)
            end
          else
            fail 'Model is not a buffer, can not be saved, modifications should be persisted as they are made.'
          end
        else
          # Some errors, mark all fields
          result = promise_for_errors(errors)
        end

        # If passed a block, call then on it with the block.
        result = result.then(&block) if block

        result
      end
    end

    # When errors come in, we mark all fields and return a rejected promise.
    def promise_for_errors(errors)
      mark_all_fields!

      # Wrap in an Errors class unless it already is one
      errors = errors.is_a?(Errors) ? errors : Errors.new(errors)

      Promise.new.reject(errors)
    end

    def buffer?
      options[:buffer] || false
    end

    # Returns a buffered version of the model
    def buffer
      model_path = options[:path]

      model_klass = self.class

      new_options = options.merge(path: model_path, save_to: self, buffer: true).reject { |k, _| k.to_sym == :persistor }

      model = nil
      Volt::Model.no_validate do
        model = model_klass.new(attributes, new_options, :loaded)

        model.instance_variable_set('@new', @new)
      end

      model
    end

    def self.included(base)
      base.include ReactiveAccessors
      base.reactive_accessor :__save_to
    end

    def save_to
      val = __save_to

      unless val
        # Lazy load the save_to
        self.save_to = options[:save_to]
        return __save_to
      end

      val
    end

    def save_to=(val)
      self.__save_to = val
    end

    def saved_state
      if buffer?
        # cache save_to in local
        lsave_to = self.save_to

        lsave_to.try(:saved_state) || :not_saved
      else
        super
      end
    end

    def saved?
      saved_state == :saved
    end
  end
end
