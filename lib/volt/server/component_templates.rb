require 'volt/server/html_parser/view_parser'
require 'volt/tasks/task'
require 'volt/server/template_handlers/preprocessors'


# Initialize with the path to a component and returns all the front-end
# setup code (for controllers, models, views, and routes)
module Volt
  class BasicHandler
    def call(file_contents)
      file_contents
    end
  end

  class ComponentTemplates
    extend ComponentTemplates::Preprocessors

    # client is if we are generating for the client or backend
    def initialize(component_path, component_name, client = true)
      @component_path = component_path
      @component_name = component_name
      @client         = client
    end

    def initializer_code
      if @client
        generate_initializers_code
      else
        ''
      end
    end

    def component_code
      code = ''

      code << generate_routes_code + generate_view_code
      if @client
        # On the backend, we just need the views
        code << generate_controller_code + generate_model_code +
                generate_tasks_code
      end

      code
    end

    def app_reference
      if @client
        'Volt.current_app'
      else
        'volt_app'
      end
    end

    def generate_view_code
      code = ''
      views_path = "#{@component_path}/views/"

      exts = Preprocessors.extensions

      # Load all templates in the folder
      Dir["#{views_path}*/*.{#{exts.join(',')}}"].sort.each do |view_path|
        if @client
          require_path = view_path.split('/')[-4..-1].join('/').gsub(/[.][^.]*$/, '')

          # On the client side, we can just require the file and let sprockets
          # handle things.
          code << "\nrequire '#{require_path}'\n"
        else
          valid_exts_re = exts.join('|')
          # On the sever side, we eval the compiled code
          path_parts = view_path.scan(/([^\/]+)\/([^\/]+)\/[^\/]+\/([^\/]+)[.](#{valid_exts_re})$/)
          component_name, controller_name, view, _ = path_parts[0]

          # file extension
          format = File.extname(view_path).downcase.delete('.').to_sym

          # Get the path for the template, supports templates in folders
          template_path = view_path[views_path.size..-1].gsub(/[.](#{valid_exts_re})$/, '')
          template_path = "#{@component_name}/#{template_path}"

          html = File.read(view_path)

          if handler = ComponentTemplates.handler_for_extension(format)
            html = handler.call(html)

            code << ViewParser.new(html, template_path).code(app_reference)
          end
        end
      end

      code
    end

    def generate_controller_code
      code             = ''
      controllers_path = "#{@component_path}/controllers/"
      views_path = "#{@component_path}/views/"

      # Controllers are optional, specifying a view folder is enough to auto
      # generate the controller.

      implicit_controllers = Dir["#{views_path}*"].sort.map do |path|
        # remove the /views/ folder and add _controller.rb
        path.split('/').tap {|v| v[-2] = 'controllers' }.join('/') + '_controller.rb'
      end
      explicit_controllers = Dir["#{controllers_path}*_controller.rb"].sort

      controllers = (implicit_controllers + explicit_controllers).uniq

      controllers.each do |path|
        if File.exists?(path)
          code << "\nrequire '#{localize_path(path)}'\n"
        else
          # parts = path.scan(/([^\/]+)\/controllers\/([^\/]+)_controller[.]rb$/)
          # component, controller = parts[0]

          # # Generate a blank controller.  (We need to actually generate one so
          # # the Template can be attached to it for template inheritance)
          # code << "\nmodule #{component.camelize}\n  class #{controller.camelize} < Volt::ModelController\n  end\nend\n"
        end
      end

      code
    end

    def generate_model_code
      code        = ''
      models_path = "#{@component_path}/models/"

      Dir["#{models_path}*.rb"].sort.each do |model_path|
        # code << File.read(model_path) + "\n\n"

        # model_name = model_path.match(/([^\/]+)[.]rb$/)[1]
        if File.exists?(model_path)
          code << "require '#{localize_path(model_path)}'\n"
        end
      end

      code
    end

    def generate_routes_code
      code        = ''
      routes_path = "#{@component_path}/config/routes.rb"

      if File.exist?(routes_path)
        code << "#{app_reference}.add_routes do\n"
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
      paths = Dir["#{@component_path}/config/initializers/*.rb"]
      paths += Dir["#{@component_path}/config/initializers/client/*.rb"]

      code = "\n" + paths.map { |path| "require '#{localize_path(path)}'" }.join("\n")

      code + "\n\n"
    end

    private

  # Takes a full path and returns the localized version so opal supprots it
    def localize_path(path)
      cpath_size = @component_path.size
      return @component_name + path[cpath_size..-1]
    end


  end
end
