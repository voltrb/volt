require 'volt/server/html_parser/view_parser'

# Initialize with the path to a component and returns all the front-end
# setup code (for controllers, models, views, and routes)
class ComponentTemplates
  def initialize(component_path, component_name, client=true)
    @component_path = component_path
    @component_name = component_name
    @client = true
  end

  def code
    code = generate_view_code
    if @client
      # On the backend, we just need the views
      code << generate_controller_code + generate_model_code + generate_routes_code + generate_tasks_code
    end

    return code
  end

  def page_reference
    if @client
      '$page'
    else
      'page'
    end
  end

  def generate_view_code
    code = ''
    views_path = "#{@component_path}/views/"

    # Load all templates in the folder
    Dir["#{views_path}*/*.html"].sort.each do |view_path|
      # Get the path for the template, supports templates in folders
      template_path = view_path[views_path.size..((-1 * ('.html'.size + 1)))]
      template_path = "#{@component_name}/#{template_path}"

      all_templates = ViewParser.new(File.read(view_path), template_path)

      binding_initializers = []
      all_templates.templates.each_pair do |name, template|
        binding_code = []

        if template['bindings']
          template['bindings'].each_pair do |key,value|
            binding_code << "#{key.inspect} => [#{value.join(', ')}]"
          end
        end

        binding_code = "{#{binding_code.join(', ')}}"

        code << "#{page_reference}.add_template(#{name.inspect}, #{template['html'].inspect}, #{binding_code})\n"
      end
    end

    return code
  end

  def generate_controller_code
    code = ''
    controllers_path = "#{@component_path}/controllers/"

    Dir["#{controllers_path}*_controller.rb"].sort.each do |controller_path|
      code << File.read(controller_path) + "\n\n"
    end

    return code
  end

  def generate_model_code
    code = ''
    models_path = "#{@component_path}/models/"

    Dir["#{models_path}*.rb"].sort.each do |model_path|
      code << File.read(model_path) + "\n\n"

      model_name = model_path.match(/([^\/]+)[.]rb$/)[1]

      code << "#{page_reference}.add_model(#{model_name.inspect})\n\n"
    end

    return code
  end

  def generate_routes_code
    code = ''
    routes_path = "#{@component_path}/config/routes.rb"

    if File.exists?(routes_path)
      code << "#{page_reference}.add_routes do\n"
      code << "\n" + File.read(routes_path) + "\n"
      code << "end\n\n"
    end

    return code
  end

  def generate_tasks_code
    return TaskHandler.known_handlers.map do |handler|
      "class #{handler.name} < TaskHandler; end"
    end.join "\n"
  end
end
