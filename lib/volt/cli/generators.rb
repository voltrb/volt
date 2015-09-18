module Generators
  def self.included(base)
    base.class_eval do
      include Thor::Actions

      desc 'model NAME COMPONENT', 'Creates a model named NAME in the component named COMPONENT'
      method_option :name, type: :string, banner: 'The name of the model.'
      method_option :component, type: :string, default: 'main', banner: 'The component the model should be created in.', required: false
      def model(name, component = 'main')
        output_file = Dir.pwd + "/app/#{component.underscore}/models/#{name.underscore.singularize}.rb"
        spec_file = Dir.pwd + "/spec/app/#{component.underscore}/models/#{name.underscore.pluralize}_spec.rb"
        template('model/model.rb.tt', output_file, model_name: name.camelize.singularize)
        template('model/model_spec.rb.tt', spec_file, model_name: name.camelize.singularize)
      end

      desc 'component NAME', 'Creates a component named NAME in the app folder.'
      method_option :name, type: :string, banner: 'The name of the component.'
      def component(name)
        name = name.underscore
        component_folder = Dir.pwd + "/app/#{name}"
        component_spec_folder = Dir.pwd + '/spec/app/' + name
        @component_name = name
        directory('component', component_folder, component_name: name)
        directory('component_specs', component_spec_folder)
      end

      desc 'gem GEM', 'Creates a component gem where you can share a component'
      method_option :bin, type: :boolean, default: false, aliases: '-b', banner: 'Generate a binary for your library.'
      method_option :test, type: :string, lazy_default: 'rspec', aliases: '-t', banner: "Generate a test directory for your library: 'rspec' is the default, but 'minitest' is also supported."
      method_option :edit, type: :string, aliases: '-e',
                           lazy_default: [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find { |e| !e.nil? && !e.empty? },
                           required: false, banner: '/path/to/your/editor',
                           desc: 'Open generated gemspec in the specified editor (defaults to $EDITOR or $BUNDLER_EDITOR)'
      method_option :coc, type: :boolean, desc: "Generate a code of conduct file. Set a default with `bundle config gem.coc true`."
      method_option :mit, type: :boolean, desc: "Generate an MIT license file"

      def gem(name)
        require 'volt/cli/new_gem'

        # remove prefixed volt-
        name = name.gsub(/^volt[-]/, '')

        if name =~ /[-]/
          require 'volt'
          require 'volt/extra_core/logger'
          Volt.logger.error('Gem names should use underscores for their names.  Currently volt only supports a single namespace for a component.')
          return
        end

        NewGem.new(self, name, options)
      end

      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), '../../../templates'))
      end

      desc 'http_controller NAME COMPONENT', 'Creates an HTTP Controller named NAME in the .'
      method_option :name, type: :string, banner: 'The name of the HTTP Controller.'
      method_option :component, type: :string, default: 'main', banner: 'The component the http_controller should be created in.', required: false
      def http_controller(name, component = 'main')
        name = name.underscore + '_controller' unless name =~ /_controller$/

        output_file = Dir.pwd + "/app/#{component}/controllers/server/#{name.underscore}.rb"
        spec_file = Dir.pwd + "/spec/app/#{component.underscore}/controllers/server/#{name}_spec.rb"

        template('controller/http_controller.rb.tt', output_file, component_module: component.camelize, http_controller_name: name.camelize)
        template('controller/http_controller_spec.rb.tt', spec_file, component_module: component.camelize, http_controller_name: name.camelize)
      end

      desc 'controller NAME COMPONENT', 'Creates a model controller named NAME in the app folder of the component named COMPONENT.'
      method_option :name, type: :string, banner: 'The name of the model controller.'
      method_option :component, type: :string, default: 'main', banner: 'The component the controller should be created in.', required: false
      def controller(name, component = 'main')
        controller_name = name.underscore + '_controller' unless name =~ /_controller$/
        output_file = Dir.pwd + "/app/#{component.underscore}/controllers/#{controller_name}.rb"
        spec_file = Dir.pwd + "/spec/app/#{component.underscore}/integration/#{name.underscore}_spec.rb"

        template('controller/model_controller.rb.tt', output_file, component_module: component.camelize, model_controller_name: controller_name.camelize)
        template('controller/model_controller_spec.rb.tt', spec_file, describe: name.underscore)
      end

      desc 'task NAME COMPONENT', 'Creates a task named NAME in the app folder of the component named COMPONENT.'
      method_option :name, type: :string, banner: 'The name of the task.'
      method_option :component, type: :string, default: 'main', banner: 'The component the task should be created in.', required: false
      def task(name, component = 'main')
        name = name.underscore.gsub(/_tasks$/, '').singularize.gsub('_task', '') + '_task'
        output_file = Dir.pwd + "/app/#{component}/tasks/#{name}.rb"
        spec_file = Dir.pwd + "/spec/app/#{component}/tasks/#{name}_spec.rb"
        template('task/task.rb.tt', output_file, task_name: name.camelize.singularize)
        template('task/task_spec.rb.tt', spec_file, task_name: name.camelize.singularize)
      end

      desc 'view NAME COMPONENT', 'Creates a view named NAME in the app folder of the component named COMPONENT.'
      method_option :name, type: :string, banner: 'The name of the view.'
      method_option :component, type: :string, default: 'main', banner: 'The component the view should be created in.', required: false
      def view(name, component = 'main')
        name = name.underscore.pluralize
        view_folder = Dir.pwd + "/app/#{component}/views/#{name}/"
        directory('view', view_folder, view_name: name, component: component)
        controller(name, component) unless controller_exists?(name, component)
      end

      private

      def controller_exists?(name, component = 'main')
        dir = Dir.pwd + "/app/#{component}/controllers/"
        File.exist?(dir + name.downcase.underscore.singularize + '.rb')
      end
    end
  end
end
