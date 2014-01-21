require 'volt/reactive/event_chain'
require 'volt/reactive/object_tracker'

DEBUG = false

# A listener gets returned when adding an 'on' event listener.  It can be
# used to clear the event listener.
class Listener
  attr_reader :scope_provider, :klass
  
  def initialize(klass, event, scope_provider, callback)
    @klass = klass
    @event = event
    @scope_provider = scope_provider
    @callback = callback

    if DEBUG && RUBY_PLATFORM == 'opal'
      # puts "e: #{event} on #{klass.inspect}"
      @@all_events ||= []
      @@all_events << self
      
      # counts = {}
      # @@all_events.each do |ev|
      #   scope = (ev.scope_provider && ev.scope_provider.scope) || nil
      #   
      #   # puts `typeof(scope)`
      #   if `typeof(scope) !== 'undefined'`
      #     counts[scope] ||= 0
      #     counts[scope] += 1
      #   end
      # end
      # 
      # puts counts.inspect
      
      `window.total_listeners = window.total_listeners || 0;`
      `window.total_listeners += 1;`
      `console.log(window.total_listeners);`
    end
  end
  
  def internal?
    @internal
  end
  
  def scope
    @scope_provider && scope_provider.respond_to?(:scope) && @scope_provider.scope
  end
  
  def call(*args)
    # raise "Triggered on removed: #{@event} on #{@klass2.inspect}" if @removed
    if @removed
      puts "Triggered on a removed event: #{@event}"
      return
    end
    
    # Queue a live value update
    if @klass.reactive?
      # We are working with a reactive value.  Its receiving an event meaning
      # something changed.  Queue an update of the value it tracks.
      @klass.object_tracker.queue_update
      # puts "Queued: #{ObjectTracker.queue.inspect}"
    end
    
    @callback.call(*args)
  end

  # Removes the listener from where ever it was created.
  def remove
    # puts "FAIL:" if @removed
    raise "event #{@event} already removed" if @removed
    
    # puts "e rem: #{@event} on #{@klass.inspect}"
    if DEBUG && RUBY_PLATFORM == 'opal'
      @@all_events.delete(self) if @@all_events
      
      `window.total_listeners -= 1;`
      `console.log("Rem", window.total_listeners);`
    end
    
    
    @removed = true
    @klass.remove_listener(@event, self)

    # puts "Removed Listener for: #{@event} - #{@scope_provider && @scope_provider.scope.inspect} from #{@klass.inspect}"

    # We need to clear these references to free the memory
    @scope_provider = nil
    @callback = nil
    # @klass2 = @klass
    @klass = nil
    # @event = nil

  end
  
  def inspect
    "<Listener:#{object_id} event=#{@event} scope=#{scope.inspect}#{' internal' if internal?}>"
  end
end

module Events
  # Add a listener for an event
  def on(event, scope_provider=nil, &block) 
    # puts "Register: #{event} on #{self.inspect}"   
    event = event.to_sym
    
    new_listener = Listener.new(self, event, scope_provider, block)
    
    @listeners ||= {}
    @listeners[event] ||= []
    @listeners[event] << new_listener

    first = @listeners[event].size == 1
    
    # When events get added, we need to notify event chains so they
    # can update and chain any new events.
    event_chain.add_event(event) if first

    # Let the included class know that an event was registered. (if it cares)
    if self.respond_to?(:event_added)
      # call event added passing the event, the scope, and a boolean if it
      # is the first time this event has been added.
      self.event_added(event, scope_provider, first)
    end

    return new_listener
  end
  
  def event_chain
    @event_chain ||= EventChain.new(self)
  end

  def listeners
    @listeners || {}
  end

  # Typically you would call .remove on the listener returned from the .on
  # method.  However, here you can also pass in the original proc to remove
  # a listener
  def remove_listener(event, listener)
    event = event.to_sym
    
    raise "Unable to delete #{event} from #{self.inspect}" unless @listeners && @listeners[event]
    
    # if @listeners && @listeners[event]
      @listeners[event].delete(listener)

      no_more_events = @listeners[event].size == 0
      if no_more_events
        # When events are removed, we need to notify any relevent chains so they
        # can remove any chained events.
        event_chain.remove_event(event)

        # No registered listeners now on this event
        @listeners.delete(event)
      end

      # Let the class we're included on know that we removed a listener (if it cares)
      if self.respond_to?(:event_removed)
        # Pass in the event and a boolean indicating if it is the last event
        self.event_removed(event, no_more_events)
      end
    # end
  end
    
  def trigger!(event, filter=nil, *args)
    are_reactive = reactive?
    # puts "TRIGGER FOR: #{event} on #{self.inspect}" if !reactive?
    ObjectTracker.process_queue if !are_reactive# && !respond_to?(:skip_current_queue_flush)
    
    event = event.to_sym
    
    if @listeners && @listeners[event]
      # puts "LISTENERS FOR #{event} on #{self.inspect} - #{@listeners[event].inspect}"
      # TODO: We have to dup here because one trigger might remove another
      @listeners[event].dup.each do |listener|
        # Call the event on each listener
        # If there is no listener, that means another event trigger removed it.
        # If there is no filter, call
        # if we aren't reactive, we should pass to all of our reactive listeners, since they
        # just proxy us.
        # If the filter exists, check it
        # puts "CHECK #{listener.inspect} : #{self.inspect} -- #{listener.klass.inspect}"   
        if (!filter || (!are_reactive && listener.scope_provider.reactive?) || filter.call(listener.scope))
          listener.call(filter, *args)
        end
      end
    end

    nil
  end
  
  # Takes a block, which passes in 
  def trigger_by_scope!(event, *args, &block)
    trigger!(event, block, *args)
  end

end