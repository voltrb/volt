require 'volt/page/bindings/template_binding'

# Component bindings are the same as template bindings, but handle components
# and do not pass their context through
class ComponentBinding < TemplateBinding
  # The context for a component binding can be either the controller, or the
  # component arguments (@arguments), with the $page as the context.  This gives
  # components access to the page collections.
  # def render_template(full_path, controller_path)
  #   # TODO: at the moment a :body section and a :title will both initialize different
  #   # controllers.  Maybe we should have a way to tie them together?
  #   controller_class, action = get_controller(controller_path)
  #
  #   model_with_parent = {parent: @context}.merge(@arguments || {})
  #
  #   if controller_class
  #     # The user provided a controller, pass in the model as an argument (in a
  #     # sub-context)
  #     args = []
  #     args << SubContext.new(model_with_parent) if @arguments
  #
  #     current_context = controller_class.new(*args)
  #     @controller = current_context
  #
  #     # Trigger the action
  #     @controller.send(action) if @controller.respond_to?(action)
  #   else
  #     # There is not a controller
  #     current_context = SubContext.new(model_with_parent, @page)
  #     @controller = nil
  #   end
  #
  #   @current_template = TemplateRenderer.new(@page, @target, current_context, @binding_name, full_path)
  #
  #   call_ready
  # end
end
