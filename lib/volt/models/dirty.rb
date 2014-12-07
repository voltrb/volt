module Volt
  # The dirty module provides helper methods for working with and tracking
  # previous values on model attributes.
  module Dirty
    def changed?(key)
      @changed_attributes.key?(key.to_sym)
    end

    def previous_attribute(key)
      @changed_attributes[key.to_sym]
    end
  end
end