# StoreRoot should already be setup when this class is already loaded.  It is a
# Volt::Model that is loaded as the base class for the root of store.
#
# In order to support setting properties directly on store, we create a table
# called "root_store_models", and create a single

require 'volt/models/root_models/root_models'

module Volt
  module StoreRootHelpers
    def model_for_root
      root = nil
      Volt::Computation.run_without_tracking do
        root = get(:root_store_models).first_or_create
      end

      root
    end


    def get(attr_name, expand = false)
      res = if attr_name.singular? && attr_name.to_sym != :id
        model_for_root.get(attr_name, expand)
      else
        super
      end

      res
    end

    def set(attr_name, value, &block)
      if attr_name.singular? && attr_name.to_sym != :id
        Volt::Computation.run_without_tracking do
          model_for_root.then do |model|
            model.set(attr_name, value, &block)
          end
        end
      else
        super
      end
      # puts "SET---"
    end
  end
end

# StoreRoot.send(:include, Volt::StoreRootHelpers)