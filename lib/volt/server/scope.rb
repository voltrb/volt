# Template parsing is fairly simple at the moment.  Basically we walk the dom and
# do two types of replacements.
# 1) replacement in text nodes
# 2) attribute replacements

class Scope
  attr_accessor :bindings, :outer_binding_number, :closed_block_scopes, :last_if_binding

  def initialize(outer_binding_number=nil)
    # For block bindings, the outer binding number lets us know what the name
    # of the comments are that go before/after this scope block.
    @outer_binding_number = outer_binding_number
    @bindings = {}
  end

  def add_closed_child_scope(scope)
    @closed_block_scopes ||= []
    @closed_block_scopes << scope
  end

  def add_binding(binding_name, setup_code)
    @bindings[binding_name] ||= []
    @bindings[binding_name] << setup_code
  end
  
  def start_if_binding(binding_name, if_binding_setup)
    @last_if_binding = [binding_name, if_binding_setup]
  end
  
  def current_if_binding
    @last_if_binding
  end
  
  def close_if_binding!
    if @last_if_binding
      binding_name, if_binding_setup = @last_if_binding
      @last_if_binding = nil
      
      add_binding(binding_name, if_binding_setup.to_setup_code)
    end
  end
  
end
