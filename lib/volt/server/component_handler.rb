require 'stringio'
require 'volt'
require 'volt/server/rack/component_code'

module Volt
  class ComponentHandler
    def initialize(component_paths)
      @component_paths = component_paths
    end

    def call(env)

      req            = Rack::Request.new(env)

      path = req.path.strip

      request_source_map = (File.extname(path) == '.map')

      # TODO: Sanatize template path
      component_name = path.gsub(/^\/components\//, '').gsub(/[.](js|map)$/, '')

      javascript_code = compile_for_component(component_name, request_source_map)

      [200, { 'Content-Type' => 'application/javascript; charset=utf-8' }, StringIO.new(javascript_code)]
    end

    def compile_for_component(component_name, map=false)
      code = ComponentCode.new(component_name, @component_paths).code

      # Compile the code
      # javascript_code = Opal.compile(code)
      builder = Opal::Builder.new.build_str(code, 'app.rb')

      if map
        js_code = builder.source_map
      else
        js_code = builder.to_s + "\n//# sourceMappingURL=#{component_name}.map"
      end

      js_code
    end
  end
end
