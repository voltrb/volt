require 'volt/models/persistors/store'

module Persistors
  class ModelStore < Store
    ID_CHARS = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|v| v.to_a }.flatten
  
    @@identity_map = {}
    
    attr_reader :model
  
    # Called when an item is added into a collection
    def loaded
      # Set the id by default
      @model.attributes[:_id] ||= generate_id
      @@identity_map[@model.attributes[:_id]] ||= self
      
      # Check to see if we already have listeners setup
      if @model.listeners[:changed]
        change_channel_connection("add")
      end
    end
    
    # Create a random unique id that can be used as the mongo id as well
    def generate_id
      id = []
      12.times { id << ID_CHARS.sample }
    
      return id.join
    end
    
    # Called when the model changes
    def changed(attribute_name)
      path_size = @model.path.size
      if !(defined?($loading_models) && $loading_models) && @tasks && path_size > 0 && !@model.nil?      
        if path_size > 3 && (parent = @model.parent) && source = parent.parent
          self.attributes[:"#{path[-4].singularize}_id"] = source._id
        end
      
        puts "Save: #{collection} - #{self_attributes.inspect}"
        @tasks.call('StoreTasks', 'save', collection, self_attributes)
      end
    end


    def event_added(event, scope_provider, first)
      if first && event == :changed
        # Start listening
        change_channel_connection("add")
      end
    end
  
    def event_removed(event, no_more_events)
      if no_more_events && event == :changed
        # Stop listening
        change_channel_connection("remove")
      end
    end
  
    def change_channel_connection(add_or_remove)
      if @model.attributes && @model.path.size > 1
        channel_name = "#{@model.path[-2]}##{@model.attributes[:_id]}"
        puts "Event Added: #{channel_name} -- #{@model.attributes.inspect}"
        @tasks.call('ChannelTasks', "#{add_or_remove}_listener", channel_name)
      end
    end
    
    def self.update(model_id, data)
      persistor = @@identity_map[model_id]
    
      if persistor
        data.each_pair do |key, value|
          if key != '_id'
            persistor.model.send(:"#{key}=", value)
          end
        end
      end
    end

    private
      # Return the attributes that are only for this store, not any sub-associations.
      def self_attributes
        # Don't store any sub-stores, those will do their own saving.
        @model.attributes.reject {|k,v| v.is_a?(Model) || v.is_a?(ArrayModel) }    
      end
    
      def collection
        @model.path[-2]
      end
    
  end
end