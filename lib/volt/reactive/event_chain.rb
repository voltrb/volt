CHAIN_DEBUG = false

class ChainListener
  attr_reader :object, :callback

  def initialize(event_chain, object, callback)
    @event_chain = event_chain
    @object = object
    @callback = callback

    if RUBY_PLATFORM == 'opal' && CHAIN_DEBUG
      `window.chain_listeners = window.chain_listeners || 0;`
      `window.chain_listeners += 1;`
      `console.log('chain listeners: ', window.chain_listeners)`
    end
  end

  def remove
    # raise "event chain already removed" if @removed
    if @removed
      puts "event chain already removed"
      return
    end

    @removed = true
    @event_chain.remove_object(self)

    # We need to clear these to free memory
    @event_chain = nil
    @object = nil
    @callback = nil

    if RUBY_PLATFORM == 'opal' && CHAIN_DEBUG
      `window.chain_listeners -= 1;`
      `console.log('del chain listeners: ', window.chain_listeners)`
    end
  end
end

class EventChain
  def initialize(main_object)
    @event_chain = {}
    @main_object = main_object
    @event_counts = {}
  end

  # Register an event listener that chains from object to self
  def setup_listener(event, chain_listener)
    return chain_listener.object.on(event, @main_object) do |filter, *args|
      if (callback = chain_listener.callback)
        callback.call(event, filter, *args)
      else
        # Trigger on this value, when it happens on the parent

        # Only pass the filter from non-reactive to reactive?  This
        # lets us scope the calls on a proxied object.
        # Filters limit which listeners are triggered, passing them to
        # the ReactiveValue's from non-reactive lets us filter at the
        # reactive level as well.
        filter = nil unless !chain_listener.object.reactive? && @main_object.reactive?

        @main_object.trigger!(event, filter, *args)
      end
    end
  end

  # We can chain our events to any other object that includes
  # Events
  def add_object(object, &block)
    chain_listener = ChainListener.new(self, object, block)

    listeners = {}

    @main_object.listeners.keys.each do |event|
      # Create a listener for each event
      listeners[event] = setup_listener(event, chain_listener)
    end

    @event_chain[chain_listener] = listeners

    return chain_listener
  end


  def remove_object(chain_listener)
    @event_chain[chain_listener].each_pair do |event,listener|
      # Unbind each listener
      # TODO: The if shouldn't be needed, but sometimes we get nil for some reason?
      listener.remove if listener
    end

    @event_chain.delete(chain_listener)
  end

  def add_event(event)
    unless @event_counts[event]
      @event_chain.each_pair do |chain_listener,listeners|
        # Only add if we haven't already chained this event
        unless listeners[event]
          listeners[event] = setup_listener(event, chain_listener)
        end
      end
    end

    @event_counts[event] ||= 0
    @event_counts[event] += 1
  end

  # Removes the event from all events in all objects
  def remove_event(event)
    if @event_counts[event]
      count = @event_counts[event] -= 1

      if count == 0
        @event_chain.each_pair do |chain_listener,listeners|
          listeners[event].remove# if listeners[event]
          listeners.delete(event)
        end

        # Also remove the event count
        @event_counts.delete(event)
      end
    end
  end
end
