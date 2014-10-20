require 'volt/page/page'

# A rack app that renders the html for a component on the backend.
module Volt
  class ComponentHtmlRenderer
    def initialize
    end

    def call(env)
      req            = Rack::Request.new(env)
      path           = req.path

      # For now just assume main
      component_name = 'main'

      page = Page.new

      component_paths = ComponentPaths.new(Volt.root)
      code            = ComponentCode.new(component_name, component_paths).code
    end
  end
end
