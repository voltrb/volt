require 'volt/page/bindings/template_binding'

# Component bindings are the same as template bindings, but handle components
# and do not pass their context through
class ComponentBinding < TemplateBinding
  # The context for a component binding can be either the controller, or the 
  # component arguments (@model), with the $page as the context.  This gives
  # components access to the page collections.
  def render_template(full_path, controller_name)
    # TODO: at the moment a :body section and a :title will both initialize different
    # controllers.  Maybe we should have a way to tie them together?
    controller = get_controller(controller_name)
    model_with_parent = {parent: @context}.merge(@model || {})
    
    if controller
      # The user provided a controller, pass in the model as an argument (in a 
      # sub-context)
      args = []
      args << SubContext.new(model_with_parent) if @model
      
      current_context = controller.new(*args)
    else
      # There is not a controller
      current_context = SubContext.new(model_with_parent, $page)
    end

    @current_template = TemplateRenderer.new(@target, current_context, @binding_name, full_path)    
  end
end