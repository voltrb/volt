# Provides methods for objects that store reactive value's to trigger
module ObjectTracking
  def __setup_tracking(key, value)
    if value.reactive?
      # TODO: We should build this in so it fires just for the current index.
      # Currently this is a big performance hit.
      chain_listener = event_chain.add_object(value.reactive_manager) do |event, filter, *args|
        yield(event, key, args)
      end
      @reactive_element_listeners ||= {}
      @reactive_element_listeners[key] = chain_listener
    end
  end
end
