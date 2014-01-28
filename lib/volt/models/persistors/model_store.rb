require 'volt/models/persistors/store'

module Persistors
  class ModelStore < Store
    ID_CHARS = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|v| v.to_a }.flatten
  
    @@identity_map = {}
    
    attr_reader :model
  
    # Called when an item is added into a collection
    def loaded
      # Set the id by default
      puts "Model: #{@model.inspect} = #{@model.attributes.inspect}"
      if @model.attributes.is_a?(Hash) && @model.attributes[:_id]
        ensure_setup
        changed
      end
    end
    
    # Called the first time a value is assigned into this model
    def ensure_setup
      @model.attributes[:_id] ||= generate_id

      if !model_in_identity_map?
        @@identity_map[@model.attributes[:_id]] ||= self
      end

      # Check to see if we already have listeners setup
      if @model.listeners[:changed]
        listen_for_changes
      end
    end
    
    def model_in_identity_map?
      @@identity_map[@model.attributes[:_id]]
    end
    
    # Create a random unique id that can be used as the mongo id as well
    def generate_id
      id = []
      12.times { id << ID_CHARS.sample }
    
      return id.join
    end
    
    # Called when the model changes
    def changed(attribute_name=nil)
      ensure_setup
      
      path_size = @model.path.size
      if !(defined?($loading_models) && $loading_models) && @tasks && path_size > 0 && !@model.nil?      
        if path_size > 3 && (parent = @model.parent) && source = parent.parent
          self.attributes[:"#{path[-4].singularize}_id"] = source._id
        end
      
        puts "Save: #{collection} - #{self_attributes.inspect} - #{@model.path.inspect}"
        @tasks.call('StoreTasks', 'save', collection, self_attributes)
      end
    end

    def listen_for_changes
      unless @change_listening
        @change_listening = true
        change_channel_connection("add")
      end
    end
    
    def stop_listening_for_changes
      if @change_listening
        @change_listening = false
        change_channel_connection("remove")
      end
    end

    def event_added(event, scope_provider, first)
      if first && event == :changed
        # Start listening
        listen_for_changes
      end
    end
  
    def event_removed(event, no_more_events)
      if no_more_events && event == :changed
        # Stop listening
        stop_listening_for_changes
      end
    end

    def channel_name
       @channel_name ||= "#{@model.path[-2]}##{@model.attributes[:_id]}"
    end
    
    # Update the models based on the id/identity map.  Usually these requests
    # will come from the backend.
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