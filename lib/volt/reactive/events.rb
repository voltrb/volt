require 'volt/reactive/event_chain'

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
    if @removed
      # puts "Triggered on a removed event: #{@event}"
      return
    end

    if @klass.reactive?
      # Update the reactive value's current value to let it know it is being
      # followed.
      @klass.update_followers if @klass.respond_to?(:update_followers)
    end

    @callback.call(*args)
  end

  # Removes the listener from where ever it was created.
  def remove
    if @removed
      # raise "event #{@event} already removed"
      puts "event #{@event} already removed"
      return
    end

    if DEBUG && RUBY_PLATFORM == 'opal'
      @@all_events.delete(self) if @@all_events

      `window.total_listeners -= 1;`
      `console.log("Rem", window.total_listeners);`
    end


    @removed = true
    @klass.remove_listener(@event, self)

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

    event = event.to_sym

    @has_listeners = true

    new_listener = Listener.new(self, event, scope_provider, block)

    @listeners ||= {}
    @listeners[event] ||= []
    @listeners[event] << new_listener

    first_for_event = @listeners[event].size == 1
    first = first_for_event && @listeners.size == 1

    # When events get added, we need to notify event chains so they
    # can update and chain any new events.
    event_chain.add_event(event) if first_for_event

    # Let the included class know that an event was registered. (if it cares)
    if self.respond_to?(:event_added)
      # call event added passing the event, the scope, and a boolean if it
      # is the first time this event has been added.
      self.event_added(event, scope_provider, first, first_for_event)
    end

    return new_listener
  end

  def event_chain
    @event_chain ||= EventChain.new(self)
  end

  def listeners
    @listeners || {}
  end

  def has_listeners?
    @has_listeners
  end

  # Typically you would call .remove on the listener returned from the .on
  # method.  However, here you can also pass in the original proc to remove
  # a listener
  def remove_listener(event, listener)
    event = event.to_sym

    raise "Unable to delete #{event} from #{self.inspect}" unless @listeners && @listeners[event]

    @listeners[event].delete(listener)

    last_for_event = @listeners[event].size == 0

    if last_for_event
      # When events are removed, we need to notify any relevent chains so they
      # can remove any chained events.
      event_chain.remove_event(event)

      # No registered listeners now on this event
      @listeners.delete(event)
    end

    last = last_for_event && @listeners.size == 0

    # Let the class we're included on know that we removed a listener (if it cares)
    if self.respond_to?(:event_removed)
      # Pass in the event and a boolean indicating if it is the last event
      self.event_removed(event, last, last_for_event)
    end

    if last
      @has_listeners = nil
    end
  end

  def trigger!(event, filter=nil, *args)
    # puts "TRIGGER: #{event} on #{self.inspect}" if event == :added
    are_reactive = reactive?

    event = event.to_sym

    if @listeners && @listeners[event]
      # TODO: We have to dup here because one trigger might remove another
      @listeners[event].dup.each do |listener|
        # Call the event on each listener
        # If there is no listener, that means another event trigger removed it.
        # If there is no filter, call
        # if we aren't reactive, we should pass to all of our reactive listeners, since they
        # just proxy us.
        # If the filter exists, check it
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

  # Takes an event and a list of method names, and triggers the event for each listener
  # coming off of those methods.
  def trigger_for_methods!(event, *method_names)
    trigger_by_scope!(event, [], nil) do |scope|
      if scope
        method_name = scope.first

        method_names.include?(method_name)
      else
        false
      end
    end
  end

end
