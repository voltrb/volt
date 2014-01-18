require 'volt/reactive/events'
require 'volt/reactive/reactive_tags'
require 'volt/reactive/string_extensions'
require 'volt/reactive/array_extensions'
require 'volt/reactive/reactive_array'
require 'volt/reactive/object_tracker'

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
  SKIP_METHODS = [:hash, :methods, :eql?, :respond_to?, :respond_to_missing?, :to_ary, :to_int]#, :instance_of?, :kind_of?, :to_s, :to_str]

  def initialize(getter, setter=nil, scope=nil)
    @reactive_manager = ::ReactiveManager.new(getter, setter, scope)
  end
  
  def reactive?
    true
  end
  
  # Proxy methods to the ReactiveManager.  We want to have as few
  # as possible methods on reactive values, so all other methods
  # are forwarded to the object the reactive value points to.
  [:cur, :cur=, :on, :trigger!, :trigger_by_scope!].each do |method_name|
    define_method(method_name) do |*args, &block|
      @reactive_manager.send(method_name, *args, &block)
    end
  end
  
  def reactive_manager
    @reactive_manager
  end
  alias_method :rm, :reactive_manager  
  
  def check_tag(method_name, tag_name)
    current_obj = cur # TODO: should be cached somehow
    
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
  
  def puts(*args)
    ::Object.send(:puts, *args)
  end
  
  def method_missing(method_name, *args, &block)
    # Unroll send into a direct call
    if method_name == :send
      method_name, *args = args
    end
    
    # Check to see if the method we're calling wants to receive reactive values.
    pass_reactive = check_tag(method_name, :pass_reactive)

    # For some methods, we pass directly to the current object.  This
    # helps ReactiveValue's be well behaved ruby citizens.
    # Also skip if this is a destructive method
    if SKIP_METHODS.include?(method_name) || check_tag(method_name, :destructive)# || (method_name[0] =~ /[a-zA-Z]/ && !cur.is_a?(::Exception))
      pass_args = pass_reactive ? args : args.map{|v| v.cur }
      return cur.__send__(method_name, *pass_args, &block)
    end
    
    @block_reactives = []
    result = @reactive_manager.with_and_options(args, pass_reactive) do |val, in_args|
      # When a method is called with a block, we pass in our own block that wraps the
      # block passed in.  This way we can pass in any arguments as reactive and track
      # the return values.
      new_block = block
      # index_cache = []
      # index = 0
      # 
      # if false && new_block
      #   new_block = ::Proc.new do |*block_args|
      #     res = block.call(*block_args.map {|v| ::ReactiveValue.new(v) })
      #     
      #     result.rm.remove_parent!(index_cache[index]) if index_cache[index]
      #     puts "index: #{index}"
      #     index_cache[index] = res
      # 
      #     # @block_reactives << res
      #     result.rm.add_parent!(res)
      #     # puts "Parent Size: #{result.rm.parents.size}"
      #     
      #     index += 1
      #     
      #     res.cur
      #   end
      # end
      
      val.__send__(method_name, *in_args, &new_block)
    end
    
    manager = result.reactive_manager
    
    setup_setter(manager, method_name, args)
    
    manager.set_scope!([method_name, *args, block])
    
    # result = result.with(block_reactives) if block
    
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
  
  def with(*args, &block)
    return @reactive_manager.with(*args, &block)
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
end

class ReactiveManager
  include ::Events
  
  attr_reader :scope, :parents
  
  # When created, ReactiveValue's get a getter (a proc)
  def initialize(getter, setter=nil, scope=nil)
    @getter = getter
    @setter = setter
    @scope = scope
    
    @parents = []
  end
  
  def reactive?
    true
  end
  
  def inspect
    "@<#{self.class.to_s}:#{reactive_object_id} #{cur.inspect}>"
  end
  
  def reactive_object_id
    @reactive_object_id ||= rand(100000)
  end
  
  
  def event_added(event, scope, first)
    # When the first event is registered, we need to start listening on our current object
    # for it to publish events.
    object_tracker.enable! if first
  end
  
  def event_removed(event, last)
    # If no one is listening on the reactive value, then we don't need to listen on our
    # current object for events, because no one cares.
    object_tracker.disable! if @listeners.size == 0
  end
  
  def object_tracker
    @object_tracker ||= ::ObjectTracker.new(self)
  end


  # Fetch the current value
  def cur
    # if @cached_obj && ObjectTracker.cache_version == @cached_version
    #   return @cached_obj
    # end
    
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
    
    if result.reactive?
      # Unwrap any stored reactive values
      result = result.cur
    end
    
    # if ObjectTracker.cache_enabled
      # @cached_obj = result
      # @cached_version = ObjectTracker.cache_version
    # end
    
    return result
  end
  
  def cur=(val)
    if @setter
      @setter.call(val)
    elsif @scope == nil
      @getter = val
      @setter = nil
      
      trigger!('changed')
    else
      raise "Value can not be updated"
    end
  end
  
  # With returns a new reactive value dependent on any arguments passed in.
  # If a block is passed in, the getter is the block its self, which will
  # be passed the .cur and the .cur of any reactive arguments.
  def with(*args, &block)
    return with_and_options(args, false, &block)
  end
  
  def with_and_options(args, pass_reactive, &block)
    getter = @getter
    setter = @setter
    scope = @scope
     
    if block
      # If a block was passed in, the getter now becomes a proc that calls
      # the passed in block with the right arguments.
      getter = ::Proc.new do
        # Unwrap arguments if the method doesn't want reactive values
        pass_args = pass_reactive ? args : args.map{|v| v.cur }
        
        # TODO: Calling cur every time
        current_val = self.cur
        
        if current_val.is_a?(Exception)
          current_val
        else
          block.call(current_val, pass_args)
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
  
  # def event_added(event, scope_provider, first)
  #   # Chain to our current value
  #   @current_obj = self.cur()
  #   
  #   if @current_obj.respond_to?(:on)
  #     @current_obj_chain_listener = event_chain.add_object(@current_obj)
  #   end
  #   
  #   
  #   # if first && event != :changed && !@other_event_listener
  #   #   @other_event_listener = on('changed') { }
  #   # end
  # end
  
  # def event_removed(event, no_more_events)
  #   if no_more_events && @current_obj_chain_listener
  #     @current_obj_chain_listener.remove
  #     @current_obj_chain_listener = nil
  #   end
  # end
  
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