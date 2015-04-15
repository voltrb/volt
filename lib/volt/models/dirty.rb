module Volt
  # The dirty module provides helper methods for working with and tracking
  # previous values on model attributes.
  module Dirty
    # Return the list of attributes that have changed since the last 'save' event.
    def changed_attributes
      @changed_attributes ||= {}
    end

    # Return true if key has changed
    def changed?(key=nil)
      if key
        # return the changed values for the keys
        changed_attributes.key?(key)
      else
        changed_attributes.present?
      end
    end

    # Grab all previous versions of for key
    def changes(key)
      changed_attributes[key]
    end

    # Grab the previous value for the key
    def was(key)
      val = changed_attributes[key]

      # Doing val && val[0] doesn't work in opal
      # https://github.com/opal/opal/issues/664
      if val
        val[0]
      else
        nil
      end
    end

    # Clear changed attributes
    def clear_tracked_changes!
      @changed_attributes = {}
    end

    # Reverts the model attributes back to the pre-change values.
    def revert_changes!
      # Reassign the first value since we started tracking
      if @changed_attributes
        @changed_attributes.each_pair do |key, value|
          @attributes[key] = value.first
        end
      end

      clear_tracked_changes!
    end

    def attribute_will_change!(attribute_name, old_value)
      # Don't track nil models
      old_value = nil if old_value.nil?

      (changed_attributes[attribute_name] ||= []) << old_value
    end

    # Handle change and was method calls
    # Example: name_was or name_changes
    def method_missing(method_name, *args, &block)
      # Quick check to see if changes or was are being called, this check
      # keeps us from needing to parse out the parts if we're not going
      # to use them.
      if method_name =~ /[_](changes|was)$/
        # Break apart the method call
        # TODO: no destructuring because of https://github.com/opal/opal/issues/663
        *parts = method_name.to_s.split('_')
        action = parts.pop
        key = parts.join('_').to_sym

        # Handle changes or was calls.
        case action
        when 'changes'
          return changes(key)
        when 'was'
          return was(key)
        end
      end

      # Otherwise, run super
      super
    end
  end
end