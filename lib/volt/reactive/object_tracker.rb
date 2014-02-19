
class ObjectTracker
  @@queue = {}
  @@cache_enabled = false
  @@cache_version = 0

  def self.cache_enabled
    @@cache_enabled
  end

  def self.enable_cache
    clear_cache
    @@cache_enabled = true
  end

  def self.disable_cache
    @@cache_enabled = false
  end

  def self.cache_version
    @@cache_version
  end

  def self.clear_cache
    @@cache_version = (@@cache_version || 0) + 1
  end

  def initialize(main_object)
    @main_object = main_object
    @enabled = false
  end

  def self.queue
    @@queue
  end

  def queue_update
    # puts "Queue: #{@main_object.inspect}"
    @@queue[self] = true
  end

  # Run through the queue and update the followers for each
  def self.process_queue
    return if @@queue.size == 0
    # puts "PROCESS QUEUE: #{@@queue.size}"
    queue = @@queue

    # puts "Update Followers #{@@queue.size}"

    # Clear before running incase someone adds during
    @@queue = {}
    # self.enable_cache

    queue.each_pair do |object_tracker,val|
      object_tracker.update_followers
    end

    # self.disable_cache

    # puts "UPDATED FOLLOWERS"
  end

  def enable!
    unless @enabled
      @enabled = true
      queue_update
    end
  end

  def disable!
    remove_followers
    @@queue.delete(self)
    @enabled = false
  end

  def update_followers
    if @enabled
      current_obj = @main_object.cur#(true)

      # puts "UPDATE ON #{current_obj.inspect}"

      if !@cached_current_obj || current_obj.object_id != @cached_current_obj.object_id
        remove_followers

        # Add to current
        should_attach = current_obj.respond_to?(:on)
        if should_attach
          @cached_current_obj = current_obj
          # puts "ATTACH: #{@cached_current_obj}"
          @current_obj_chain_listener = @main_object.event_chain.add_object(@cached_current_obj)
        end
      end
    else
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
