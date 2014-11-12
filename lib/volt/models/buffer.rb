module Volt
  module Buffer

    def save!
      # Compute the erros once
      errors = self.errors

      if errors.size == 0
        save_to = options[:save_to]
        if save_to
          if save_to.is_a?(ArrayModel)
            # Add to the collection
            promise = save_to.append(attributes)
          else
            # We have a saved model
            promise = save_to.assign_attributes(attributes)
          end

          return promise.then do |new_model|
            if new_model
              # Set the buffer's id to track the main model's id
              attributes[:_id] = new_model._id
              options[:save_to]     = new_model
            end

            nil
          end.fail do |errors|
            if errors.is_a?(Hash)
              server_errors.replace(errors)
            end

            promise_for_errors(errors)
          end
        else
          fail 'Model is not a buffer, can not be saved, modifications should be persisted as they are made.'
        end
      else
        # Some errors, mark all fields
        promise_for_errors(errors)
      end
    end

    # When errors come in, we mark all fields and return a rejected promise.
    def promise_for_errors(errors)
      mark_all_fields!

      Promise.new.reject(errors)
    end

    # Returns a buffered version of the model
    def buffer
      model_path = options[:path]

      # When we grab a buffer off of a plual class (subcollection), we get it as a model.
      if model_path.last.plural? && model_path[-1] != :[]
        model_klass = class_at_path(model_path + [:[]])
      else
        model_klass = class_at_path(model_path)
      end

      new_options = options.merge(path: model_path, save_to: self).reject { |k, _| k.to_sym == :persistor }
      model       = model_klass.new({}, new_options, :loading)

      if state == :loaded
        setup_buffer(model)
      else
        parent.then do
          setup_buffer(model)
        end
      end

      model
    end
  end
end