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
  def event_added(event, scope_provider, first)
    @persistor.event_added(event, scope_provider, first) if @persistor
  end
  
  # Pass to the persistor
  def event_removed(event, no_more_events)
    @persistor.event_removed(event, no_more_events) if @persistor
  end
end