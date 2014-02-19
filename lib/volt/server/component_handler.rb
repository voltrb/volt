require 'stringio'
require 'volt'
require 'volt/server/html_parser/view_parser'
require 'volt/server/component_templates'
require 'volt/server/rack/asset_files'

class ComponentHandler
  def initialize(component_paths)
    @component_paths = component_paths
  end

  def call(env)
    req = Rack::Request.new(env)

    # TODO: Sanatize template path
    component_name = req.path.strip.gsub(/^\/components\//, '').gsub(/[.]js$/, '')

    code = ''

    asset_files = AssetFiles.new(component_name, @component_paths)
    asset_files.component_paths.each do |component_path, component_name|
      puts "COMP PATH: #{component_path}"
      code << ComponentTemplates.new(component_path, component_name).code
      code << "\n\n"
    end

    javascript_code = Opal.compile(code)

    # puts "ENV: #{env.inspect}"
    [200, {"Content-Type" => "text/html"}, StringIO.new(javascript_code)]
  end


end
