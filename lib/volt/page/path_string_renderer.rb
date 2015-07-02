# The PathRenderer is a simple way to render a string of the contents of a view
# at the passed in path.

require 'volt/page/bindings/view_binding/view_lookup_for_path'
require 'volt/page/bindings/view_binding/controller_handler'
require 'volt/page/string_template_renderer'

module Volt
  class ViewLookupException < Exception; end
  class PathStringRenderer
    attr_reader :html
    def initialize(volt_app, path, attrs = nil, render_from_path = nil)
      # where to do the path lookup from
      render_from_path ||= 'main/main/main/body'

      # Make path into a full path
      @view_lookup = Volt::ViewLookupForPath.new(volt_app.templates, render_from_path)
      full_path, controller_path = @view_lookup.path_for_template(path, nil)

      if full_path.nil?
        fail ViewLookupException, "Unable to find view at `#{path}`"
      end

      controller_class, action = ControllerHandler.get_controller_and_action(controller_path)

      controller = controller_class.new(volt_app) # (SubContext.new(attrs, nil, true))
      controller.model = SubContext.new(attrs, nil, true)

      renderer = StringTemplateRenderer.new(volt_app, controller, full_path)

      @html = renderer.html

      # remove when done
      renderer.remove
    end
  end
end
