# StoreRoot should already be setup when this class is already loaded.  It is a
# Volt::Model that is loaded as the base class for the root of store.
#
# In order to support setting properties directly on store, we create a table
# called "root_store_models", and create a single

require 'volt/models/root_models/root_models'

module Volt
  module StoreRootHelpers
    def model_for_root
      root = get(:root_store_models).first_or_create

      root
    end


    def get(attr_name, expand = false)
      if attr_name.singular? && attr_name.to_sym != :id
        model_for_root.get(attr_name, expand)
      else
        super
      end
    end

    def set(attr_name, value, &block)
      if attr_name.singular? && attr_name.to_sym != :id
        model_for_root.set(attr_name, value, &block)
      else
        super
      end
    end
  end
end

StoreRoot.send(:include, Volt::StoreRootHelpers)