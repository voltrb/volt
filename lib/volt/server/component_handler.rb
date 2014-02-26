require 'stringio'
require 'volt'
require 'volt/server/rack/component_code'

class ComponentHandler
  def initialize(component_paths)
    @component_paths = component_paths
  end

  def call(env)
    req = Rack::Request.new(env)

    # TODO: Sanatize template path
    component_name = req.path.strip.gsub(/^\/components\//, '').gsub(/[.]js$/, '')

    code = ComponentCode.new(component_name, @component_paths).code

    # puts "CODE: #{code}"

    javascript_code = Opal.compile(code)

    # puts "ENV: #{env.inspect}"
    [200, {"Content-Type" => "text/html"}, StringIO.new(javascript_code)]
  end


end
