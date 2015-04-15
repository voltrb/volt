# The yield binding renders the content of a tag which passes in

require 'volt/page/bindings/base_binding'
require 'volt/page/template_renderer'

module Volt
  class YieldBinding < BaseBinding
    def initialize(page, target, context, binding_name)
      super(page, target, context, binding_name)

      # Get the path to the template to yield
      full_path = @context.attrs.content_template_path

      # Grab the controller for the content
      controller = @context.attrs.content_controller

      @current_template = TemplateRenderer.new(@page, @target, controller, @binding_name, full_path)
    end

    def remove
      if @current_template
        # Remove the template if one has been rendered, when the template binding is
        # removed.
        @current_template.remove
      end

      super

    end
  end
end