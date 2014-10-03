# A place for things shared between an ArrayModel and a Model

module ModelHelpers
  def deep_unwrap(value)
    if value.is_a?(Model)
      value = value.to_h
    elsif value.is_a?(ArrayModel)
      value = value.to_a
    end

    return value
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
    if path && path.last == :[]
      begin
        # TODO: SECURITY on the back-end we need to check that the model class we're loading
        # is coming from the models folder.

        # remove the _ and then singularize
        klass_name = path[-2][1..-1].singularize.camelize

        klass_name = klass_name.camelize
        klass = Object.send(:const_get, klass_name.to_sym)
      rescue NameError => e
        # Ignore exception, just means the model isn't defined
        klass = Model
      end
    else
      klass = Model
    end

    return klass
  end
end
