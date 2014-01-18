OBJECT_TRACKER_DEBUG = false

class ObjectTracker
  @@queue = {}
  @@cache_enabled = false
  @@cache_version = 0
  
  def self.cache_enabled
    @@cache_enabled
  end
  
  def self.cache_version
    @@cache_version
  end
  
  def self.clear_cache
    @@cache_version = (@@cache_version || 0) + 1
  end
  
  def initialize(main_object)
    # puts "NEW OBJECT TRACKER FOR: #{main_object.inspect}"
    @main_object = main_object
    @enabled = false
  end
  
  def self.queue
    @@queue
  end
  
  def queue_update
    puts "QUEUE UPDATE" if OBJECT_TRACKER_DEBUG
    @@queue[self] = true
  end
  
  # Run through the queue and update the followers for each
  def self.process_queue
    # puts "PROCESS QUEUE: #{@@queue.size}"
    puts "Process #{@@queue.size} items" if OBJECT_TRACKER_DEBUG
    # TODO: Doing a full dup here is expensive?
    queue = @@queue.dup
    
    # Clear before running incase someone adds during
    @@queue = {}

    @@cache_enabled = true
    self.clear_cache

    queue.each_pair do |object_tracker,val|
      object_tracker.update_followers
    end
    
    @@cache_enabled = false
    
  end
  
  def enable!
    unless @enabled
      puts "Enable OBJ Tracker" if OBJECT_TRACKER_DEBUG
      @enabled = true
      queue_update
    end
  end
  
  def disable!
    puts "Disable OBJ Tracker" if OBJECT_TRACKER_DEBUG
    remove_followers
    @@queue.delete(self)
    @enabled = false
  end

  def update_followers
    if @enabled
      puts "UPDATE" if OBJECT_TRACKER_DEBUG
      current_obj = @main_object.cur#(true)
      
      # puts "UPDATE ON #{current_obj.inspect}"
    
      remove_followers
  
      # Add to current
      should_attach = current_obj.respond_to?(:on)
      if should_attach
        # TODO: TRACK
        @cached_current_obj = current_obj
        @current_obj_chain_listener = @main_object.event_chain.add_object(@cached_current_obj)
      end
    else
      puts "DISABLED, no update" if OBJECT_TRACKER_DEBUG
    end
  end
  
  # Remove follower
  def remove_followers
    # Remove from previous
    if @cached_current_obj
      @current_obj_chain_listener.remove
      @current_obj_chain_listener = nil
      
      @cached_current_obj = nil
    end
  end
end