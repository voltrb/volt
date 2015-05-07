# ModelChangeHelpers handle validating and persisting the data in a model
# when it is changed.  #run_changed will be called from the model.

module Volt
  module ModelChangeHelpers
    private

    # Called when something in the model changes.  Saves
    # the model if there is a persistor, and changes the
    # model to not be new.
    #
    # @return [Promise|nil] a promise for when the save is
    #         complete
    def run_changed(attribute_name = nil)
      # no_validate mode should only be used internally.  no_validate mode is a
      # performance optimization that prevents validation from running after each
      # change when assigning multile attributes.
      unless Volt.in_mode?(:no_validate)
        # Run the validations for all fields
        result = nil
        return validate!.then do
          # Buffers are allowed to be in an invalid state
          unless buffer?
            # First check that all local validations pass
            if error_in_changed_attributes?
              # Some errors are present, revert changes
              revert_changes!

              # After we revert, we need to validate again to get the error messages back
              # TODO: Could probably cache the previous errors.
              result = validate!.then do
                # Reject the promise with the errors
                Promise.new.reject(errs)
              end
            else
              result = persist_changes(attribute_name)
            end
          end

          # Return result inside of the validate! promise
          result
        end
      end

      # Didn't run validations
      nil
    end


    # Should only be called from run_changed.  Saves the changes back to the persistor
    # and clears the tracked changes.
    def persist_changes(attribute_name)
      # No errors, tell the persistor to handle the change (usually save)

      # Don't save right now if we're in a nosave block
      unless Volt.in_mode?(:no_save)
        # the changed method on a persistor should return a promise that will
        # be resolved when the save is complete, or fail with a hash of errors.
        if @persistor
          result = @persistor.changed(attribute_name)
        else
          result = Promise.new.resolve(nil)
        end

        # Saved, no longer new
        @new = false

        # Clear the change tracking
        clear_tracked_changes!
      end

      result
    end

  end
end