# StoreRoot should already be setup when this class is already loaded.  It is a
# Volt::Model that is loaded as the base class for the root of store.
#
# In order to support setting properties directly on store, we create a table
# called "root_store_models", and create a single
class StoreRoot
  def model_for_root
    root = get(:root_store_models).first_or_create

    root
  end


  def get(attr_name, expand = false)
    if attr_name.singular?
      model_for_root.get(attr_name, expand).fail do |err|
        puts "GOT ERR: #{err.inspect}"
      end
    else
      super
    end
  end

  def set(attribute_name, value, &block)
    if attribute_name.singular?
      model_for_root.set(attribute_name, value, &block).fail do |err|
        puts "GOT ERR: #{err.inspect}"
      end
    else
      super
    end
  end


end