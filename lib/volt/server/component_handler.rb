require 'stringio'
require 'volt'
require 'volt/server/template_parser'

class ComponentHandler
  def call(env)
    req = Rack::Request.new(env)

    # TODO: Sanatize template path
    @component_path = req.path.strip.gsub(/^\/components\//, '').gsub(/[.]js$/, '')

    code = generate_controller_code + generate_view_code + generate_model_code + generate_routes_code

    javascript_code = Opal.compile(code)

    # puts "ENV: #{env.inspect}"
    [200, {"Content-Type" => "text/html"}, StringIO.new(javascript_code)]
  end

  def generate_view_code
    code = ''
    views_path = Volt.root + "/app/#{@component_path}/views/"

    # Load all templates in the folder
    Dir["#{views_path}*/*.html"].each do |view_path|
      # Get the path for the template, supports templates in folders
      template_path = view_path[views_path.size..((-1 * ('.html'.size + 1)))]
      template_path = "#{@component_path}/#{template_path}"
      # puts "Template Path: #{template_path.inspect}"

      all_templates = TemplateParser.new(File.read(view_path), template_path)

      binding_initializers = []
      all_templates.templates.each_pair do |name, template|
        binding_code = []

        template['bindings'].each_pair do |key,value|
          binding_code << "#{key.inspect} => [#{value.join(', ')}]"
        end

        binding_code = "{#{binding_code.join(', ')}}"

        code << "$page.add_template(#{name.inspect}, #{template['html'].inspect}, #{binding_code})\n"
      end
    end
    # puts "--------------"
    # puts "CODE: #{code}"

    return code
  end

  def generate_controller_code
    code = ''
    controllers_path = Volt.root + "/app/#{@component_path}/controllers/"

    Dir["#{controllers_path}*_controller.rb"].each do |controller_path|
      code << File.read(controller_path) + "\n\n"
    end

    return code
  end
  
  def generate_model_code
    code = ''
    models_path = Volt.root + "/app/#{@component_path}/models/"

    Dir["#{models_path}*.rb"].each do |model_path|
      code << File.read(model_path) + "\n\n"
      
      model_name = model_path.match(/([^\/]+)[.]rb$/)[1]
      
      code << "$page.add_model(#{model_name.inspect})\n\n"
    end

    return code
  end
  
  def generate_routes_code
    code = ''
    routes_path = Volt.root + "/app/#{@component_path}/config/routes.rb"
    
    code << "$page.add_routes do\n"
    code << "\n" + File.read(routes_path) + "\n"
    code << "end\n\n"

    return code
  end
end