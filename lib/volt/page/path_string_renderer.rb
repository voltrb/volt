# The PathRenderer is a simple way to render a string of the contents of a view
# at the passed in path.

require 'volt/page/bindings/view_binding/view_lookup_for_path'
require 'volt/page/bindings/view_binding/controller_handler'
require 'volt/page/string_template_renderer'

module Volt
  class PathStringRenderer
    attr_reader :html
    def initialize(path, attrs=nil, page=nil)
      # use the global page if one is not passed in
      page ||= $page

      # Make path into a full path
      @view_lookup = Volt::ViewLookupForPath.new(page, "main/main/main/body")
      full_path, controller_path = @view_lookup.path_for_template(path, nil)

      controller_class, action = ControllerHandler.get_controller_and_action(controller_path)

      controller = controller_class.new(SubContext.new(attrs, nil, true))

      renderer = StringTemplateRenderer.new(page, controller, full_path)

      @html = renderer.html

      # remove when done
      renderer.remove
    end

  end
end