require 'volt/reactive/events'
require 'volt/reactive/reactive_tags'
require 'volt/reactive/string_extensions'
require 'volt/reactive/array_extensions'
require 'volt/reactive/reactive_array'
require 'volt/reactive/destructive_methods'
require 'volt/reactive/reactive_generator'

class Object
  def cur
    self
  end

  def reactive?
    false
  end
end

class ReactiveValue < BasicObject
  # methods on ReactiveValues:
  # reactive?, cur, with, on, data, trigger!
  # - everything else is forwarded to the ReactiveManager

  # Methods we should skip wrapping the results in
  # We skip .hash because in uniq it has .to_int called on it, which needs to
  # return a Fixnum instance.
  # :hash -   needs something where .to_int can be called on it and it will
  #           return an int
  # :methods- needs to return a straight up array to work with irb tab completion
  # :eql?   - needed for .uniq to work correctly
  # :to_ary - in some places ruby expects to get an array back from this method
  SKIP_METHODS = [:object_id, :hash, :methods, :eql?, :respond_to?, :respond_to_missing?, :to_ary, :to_int]#, :instance_of?, :kind_of?, :to_s, :to_str]

  def initialize(getter, setter=nil, scope=nil)
    @reactive_manager = ::ReactiveManager.new(self, getter, setter, scope)
    # @reactive_cache = {}
  end

  def reactive?
    true
  end

  # Proxy methods to the ReactiveManager.  We want to have as few
  # as possible methods on reactive values, so all other methods
  # are forwarded to the object the reactive value points to.
  [:cur, :cur=, :deep_cur, :on, :trigger!, :trigger_by_scope!, :with].each do |method_name|
    define_method(method_name) do |*args, &block|
      @reactive_manager.send(method_name, *args, &block)
    end
  end

  def reactive_manager
    @reactive_manager
  end
  alias_method :rm, :reactive_manager

  def puts(*args)
    ::Object.send(:puts, *args)
  end

  def __is_destructive?(method_name)
    last_char = method_name[-1]
    if last_char == '=' && method_name[-2] != '='
      # Method is an assignment (and not a comparator ==)
      return true
    elsif method_name.size > 1 && last_char == '!' || last_char == '<'
      # Method is tagged as destructive, or is a push ( << )
      return true
    elsif ::DestructiveMethods.might_be_destructive?(method_name)
      # Method may be destructive, check if it actually is on the current value
      # TODO: involves a call to cur
      return reactive_manager.check_tag(method_name, :destructive, self.cur)
    else
      return false
    end
  end

  def method_missing(method_name, *args, &block)
    # Unroll send into a direct call
    if method_name == :send
      method_name, *args = args
    end

    # result = @reactive_cache[[method_name, args.map(&:object_id)]]
    # return result if result

    # For some methods, we pass directly to the current object.  This
    # helps ReactiveValue's be well behaved ruby citizens.
    # Also skip if this is a destructive method
    if SKIP_METHODS.include?(method_name) || __is_destructive?(method_name)
      current_obj = self.cur

      # Unwrap arguments if the method doesn't want reactive values
      pass_args = reactive_manager.unwrap_if_pass_reactive(args, method_name, current_obj)

      return current_obj.__send__(method_name, *pass_args, &block)
    end

    result = @reactive_manager.with_and_options(args) do |val, in_args|
      # Unwrap arguments if the method doesn't want reactive values
      # TODO: Should cache the lookup on pass_reactive
      pass_args = reactive_manager.unwrap_if_pass_reactive(in_args, method_name, val)

      val.__send__(method_name, *pass_args, &block)
    end

    manager = result.reactive_manager

    setup_setter(manager, method_name, args)

    manager.set_scope!([method_name, *args, block])

    # result = result.with(block_reactives) if block

    # if args.size == 0 || method_name == :[]
      # @reactive_cache[[method_name, args.map(&:object_id)]] = result
    # end

    return result
  end

  def setup_setter(manager, method_name, args)
    # See if we can automatically create a setter.  If we are fetching a
    # value via a read, we can probably reassign it with .name=
    if args.size == 0
      # TODO: At the moment we are defining a setter on all "reads", this
      # probably has some performance implications
      manager.setter! do |val|
        # Call setter
        self.cur.send(:"#{method_name}=", val)
      end
    elsif args.size == 1 && method_name == :[]
      manager.setter! do |val|
        # Call an array setter
        self.cur.send(:"#{method_name}=", args[0], val)
      end
    end
  end
  #
  # def respond_to?(name, include_private=false)
  #   [:event_added, :event_removed].include?(name) || super
  # end

  def respond_to_missing?(name, include_private=false)
    cur.respond_to?(name)
  end

  def inspect
    "@#{cur.inspect}"
  end

  def pretty_inspect
    inspect
  end

  # Not 100% sure why, but we need to define this directly, it doesn't call
  # on method missing
  def ==(val)
    method_missing(:==, val)
  end

  # TODO: this is broke in opal
  def !
    method_missing(:!)
  end

  def to_s
    cur.to_s
  end

  def coerce(other)
    if other.reactive?
      return [other, self]
    else
      wrapped_object = ::ReactiveValue.new(other, [])
      return [wrapped_object, self]
    end
  end

  # Return a new reactive value that listens for changes on any
  # ReactiveValues inside of its children (hash values, array items, etc..)
  # This is useful if someone is passing in a set of options, but the main
  # hash isn't a ReactiveValue, but you want to listen for changes inside
  # of the hash.
  #
  # skip_if_no_reactives lets you get back a non-reactive value in the event
  #    that there are no child reactive values.
  def self.from_hash(hash, skip_if_no_reactives=false)
    ::ReactiveGenerator.from_hash(hash)
  end
end

class ReactiveManager
  include ::Events

  attr_reader :scope, :parents

  # When created, ReactiveValue's get a getter (a proc)
  def initialize(reactive_value, getter, setter=nil, scope=nil)
    @reactive_value = reactive_value
    @getter = getter
    @setter = setter
    @scope = scope

    @parents = []
  end

  def reactive_value
    @reactive_value
  end

  def reactive?
    true
  end

  def inspect
    "@<#{self.class.to_s}:#{object_id} #{cur.inspect}>"
  end

  def reactive_object_id
    @reactive_object_id ||= rand(100000)
  end


  def event_added(event, scope, first, first_for_event)
    # When the first event is registered, we need to start listening on our current object
    # for it to publish events.

    update_followers if first
  end

  def event_removed(event, last, last_for_event)
    # If no one is listening on the reactive value, then we don't need to listen on our
    # current object for events, because no one cares.

    remove_followers if last
  end


  # Fetch the current value
  def cur(shallow=false, ignore_cache=false)
    # Use cache if it is cached
    if @cur_cache && !shallow && !ignore_cache
      # We might be caching another reactive value, so we just set
      # it as the result and let it get unwrapped.
      result = @cur_cache
    else
      if @getter.class == ::Proc
        # Get the current value, capture any errors
        begin
          result = @getter.call
        rescue => e
          result = e
        end
      else
        # getter is just an object, return it
        result = @getter
      end
    end

    if !shallow && result.reactive?
      # Unwrap any stored reactive values
      result = result.cur
    end

    return result
  end


  def update_followers
    return if @setting_up
    if has_listeners?
      current_obj = cur(true, true)
      should_attach = current_obj.respond_to?(:on)

      if should_attach
        if !@cur_cache || current_obj.object_id != @cur_cache.object_id
          remove_followers

          @setting_up = true
          @cur_cache_chain_listener = self.event_chain.add_object(current_obj)
          @setting_up = nil
        end
      else
        remove_followers
      end

      # Store current if we have listeners
      @cur_cache = current_obj
    end

  end

  def remove_followers
    # Remove from previous
    if @cur_cache
      @cur_cache = nil
    end

    if @cur_cache_chain_listener
      @cur_cache_chain_listener.remove
      @cur_cache_chain_listener = nil
    end
  end

  def cur=(val)
    if @setter
      @setter.call(val)
      # update_followers
    elsif @scope == nil
      @getter = val
      @setter = nil

      # update_followers
      trigger!('changed')
    else
      raise "Value can not be updated"
    end

  end

  # Returns a copy of the object with where all ReactiveValue's are replaced
  # with their current value.
  # NOTE: Classes need to implement their own deep_cur method for this to work,
  # it works out of the box with arrays and hashes.
  def deep_cur
    self.cur.deep_cur
  end

  # Method calls can be tagged so the reactive value knows
  # how to handle them.  This lets you check the state of
  # the tags.
  def check_tag(method_name, tag_name, current_obj)
    if current_obj.respond_to?(:reactive_method_tag)
      tag = current_obj.reactive_method_tag(method_name, tag_name)

      unless tag
        # Get the tag from the all methods if its not directly specified
        tag = current_obj.reactive_method_tag(:__all_methods, tag_name)
      end

      # Evaluate now if its a proc
      tag = tag.call(method_name) if tag.class == ::Proc

      return tag
    end

    return nil
  end

  def unwrap_if_pass_reactive(args, method_name, current_obj)
    # Check to see if the method we're calling wants to receive reactive values.
    pass_reactive = check_tag(method_name, :pass_reactive, current_obj)

    # Unwrap arguments if the method doesn't want reactive values
    return pass_reactive ? args : args.map{|v| v.cur }
  end

  # With returns a new reactive value dependent on any arguments passed in.
  # If a block is passed in, the getter is the block its self, which will
  # be passed the .cur and the .cur of any reactive arguments.
  def with(*args, &block)
    return with_and_options(args, &block)
  end

  def with_and_options(args, &block)
    getter = @getter
    setter = @setter
    scope = @scope

    if block
      # If a block was passed in, the getter now becomes a proc that calls
      # the passed in block with the right arguments.
      getter = ::Proc.new do
        # TODO: Calling cur every time
        current_val = self.cur

        if current_val.is_a?(Exception)
          current_val
        else
          block.call(current_val, args)
        end
      end

      # TODO: Make this work with custom setters
      setter = nil

      # Scope also gets set to nil, because now we should always retrigger this
      # method because we don't know enough about what methods its calling.
      scope = nil
    end

    new_val = ReactiveValue.new(getter, setter, scope)

    # Add the ReactiveValue we're building from
    new_val.reactive_manager.add_parent!(self)

    # Add any reactive arguments as parents
    args.select(&:reactive?).each do |arg|
      new_val.reactive_manager.add_parent!(arg.reactive_manager)
    end

    return new_val
  end

  def add_parent!(parent)
    @parents << parent
    event_chain.add_object(parent)
  end

  def remove_parent!(parent)
    @parents.delete(parent)
    event_chain.remove_object(parent)
  end


  def set_scope!(new_scope)
    @scope = new_scope

    self
  end

  def set_scope(new_scope)
    dup.scope!(new_scope)
  end

  # Sets the setter
  def setter!(setter=nil, &block)
    @setter = setter || block
  end

end
