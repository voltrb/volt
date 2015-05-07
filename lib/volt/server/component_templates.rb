require 'volt/server/html_parser/view_parser'
require 'volt/tasks/task_handler'

# Initialize with the path to a component and returns all the front-end
# setup code (for controllers, models, views, and routes)
module Volt
  class BasicHandler
    def call(file_contents)
      file_contents
    end
  end

  class ComponentTemplates
    
    module Handlers #:nodoc:
      # Setup default handler on extend
      def self.extended(base)
        base.register_template_handler :html, BasicHandler.new
        base.register_template_handler :email, BasicHandler.new
      end

      @@template_handlers = {}
      
      def self.extensions
        @@template_extensions ||= @@template_handlers.keys
      end

      # Register an object that knows how to handle template files with the given
      # extensions. This can be used to implement new template types.
      # The handler must respond to +:call+, which will be passed the template
      # and should return the rendered template as a String.
      def register_template_handler(extension, handler)
        @@template_handlers[extension.to_sym] = handler
      end

      def registered_template_handler(extension)
        extension && @@template_handlers[extension.to_sym]
      end

      def handler_for_extension(extension)
        registered_template_handler(extension)
      end
    end

    extend ComponentTemplates::Handlers

    
    # client is if we are generating for the client or backend
    def initialize(component_path, component_name, client = true)
      @component_path = component_path
      @component_name = component_name
      @client         = client
    end

    def code
      code = generate_routes_code + generate_view_code
      if @client
        # On the backend, we just need the views
        code << generate_controller_code + generate_model_code + generate_tasks_code + generate_initializers_code
      end

      code
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

      exts = Handlers.extensions

      # Load all templates in the folder
      Dir["#{views_path}*/*.{#{exts.join(',')}}"].sort.each do |view_path|
        # file extension
        format = File.extname(view_path).downcase.delete('.').to_sym

        # Get the path for the template, supports templates in folders
        template_path = view_path[views_path.size..-1].gsub(/[.](#{exts.join('|')})$/, '')
        template_path = "#{@component_name}/#{template_path}"

        file_contents = File.read(view_path)

        # Process template if we have a handler for this file type
        if handler = ComponentTemplates.handler_for_extension(format)
          file_contents = handler.call(file_contents)
        
          all_templates = ViewParser.new(file_contents, template_path)

          binding_initializers = []
          all_templates.templates.each_pair do |name, template|
            binding_code = []

            if template['bindings']
              template['bindings'].each_pair do |key, value|
                binding_code << "#{key.inspect} => [#{value.join(', ')}]"
              end
            end

            binding_code = "{#{binding_code.join(', ')}}"

            code << "#{page_reference}.add_template(#{name.inspect}, #{template['html'].inspect}, #{binding_code})\n"
          end
        end
      end

      code

    end

    def generate_controller_code
      code             = ''
      controllers_path = "#{@component_path}/controllers/"

      Dir["#{controllers_path}*_controller.rb"].sort.each do |controller_path|
        code << File.read(controller_path) + "\n\n"
      end

      code
    end

    def generate_model_code
      code        = ''
      models_path = "#{@component_path}/models/"

      Dir["#{models_path}*.rb"].sort.each do |model_path|
        code << File.read(model_path) + "\n\n"

        model_name = model_path.match(/([^\/]+)[.]rb$/)[1]
      end

      code
    end

    def generate_routes_code
      code        = ''
      routes_path = "#{@component_path}/config/routes.rb"

      if File.exist?(routes_path)
        code << "#{page_reference}.add_routes do\n"
        code << "\n" + File.read(routes_path) + "\n"
        code << "end\n\n"
      end

      code
    end

    def generate_tasks_code
      Task.known_handlers.map do |handler|
        # Split into modules and class
        klass_parts = handler.name.split('::')

        # Start with the inner class
        parts = ["class #{klass_parts.pop} < Volt::Task; end"]

        # Work backwards on the modules
        klass_parts.reverse_each do |kpart|
          parts.unshift("module #{kpart}")
          parts.push('end')
        end

        # Combine the parts
        parts.join("\n")
      end.join "\n" # combine all into one string
    end

    def generate_initializers_code
      "\nrequire_tree '#{@component_path}/config/initializers/'\n"
    end

  end
end
