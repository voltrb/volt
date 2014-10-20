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

      # TODO: Sanatize template path
      component_name = req.path.strip.gsub(/^\/components\//, '').gsub(/[.]js$/, '')

      javascript_code = compile_for_component(component_name)

      [200, { 'Content-Type' => 'application/javascript; charset=utf-8' }, StringIO.new(javascript_code)]
    end

    def compile_for_component(component_name)
      code = ComponentCode.new(component_name, @component_paths).code

      # Add the lib directory to the load path
      Opal.append_path(Volt.root + '/lib')

      # Compile the code
      javascript_code = Opal.compile(code)

      javascript_code
    end
  end
end
