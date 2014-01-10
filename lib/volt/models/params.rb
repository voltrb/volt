# All url related data is stored in params.  This includes the main uri
# in addition to any query parameters.  The router is responsible for
# converting any uri sections into params.  Sections in the uri will
# override any specified parameters.
#
# The params value can be updated the same way a model would be, only
# the updates will trigger an updated url via the browser history api.
# TODO: Support # for browsers without the history api.

class Params < Model    
  def initialize(*args)
    super(*args)
  end
  
  def deep_clone
    new_obj = clone
    
    new_obj.attributes = new_obj.attributes.dup
    
    new_obj
  end

  tag_method(:delete) do
    destructive!
  end
  def delete(*args)
    super
    
    value_updated
  end

  def method_missing(method_name, *args, &block)
    result = super
    
    if method_name[0] == '_' && method_name[-1] == '='
      # Trigger value updated after an assignment
      self.value_updated
    end
    
    return result
  end
  
  def value_updated
    # Once the initial url has been parsed and set into the attributes,
    # start triggering updates on change events.
    # TODO: This is a temp solution, we need to make it so value_updated
    # is called after the reactive_value has been updated.
    if RUBY_PLATFORM == 'opal'
      %x{
        if (window.setTimeout && this.$run_update.bind) {
          if (window.paramsUpdateTimer) {
            clearTimeout(window.paramsUpdateTimer);
          }
          window.paramsUpdateTimer = setTimeout(this.$run_update.bind(this), 0);
        }
      }
    end
  end
  
  def run_update
    $page.params.trigger!('child_changed') if Volt.client?
  end
  
  def new_model(*args)
    Params.new(*args)
  end
end
