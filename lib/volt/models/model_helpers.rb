module Volt
  # A place for things shared between an ArrayModel and a Model
  module ModelHelpers
    def deep_unwrap(value)
      if value.is_a?(Model)
        value.to_h
      elsif value.is_a?(ArrayModel)
        value.to_a
      else
        value
      end
    end

    # Pass to the persisotr
    def event_added(event, first, first_for_event)
      @persistor.event_added(event, first, first_for_event) if @persistor
    end

    # Pass to the persistor
    def event_removed(event, last, last_for_event)
      @persistor.event_removed(event, last, last_for_event) if @persistor
    end

    # Gets the class for a model at the specified path.
    def class_at_path(path)
      if path
        begin
          # remove the _ and then singularize
          if path.last == :[]
            index = -2
          else
            index = -1
          end

          klass_name = path[index].singularize.camelize

          klass = $page.model_classes[klass_name] || Model
        rescue NameError => e
          # Ignore exception, just means the model isn't defined
          klass = Model
        end
      else
        klass = Model
      end

      klass
    end
  end
end
