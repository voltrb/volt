class Generate < Thor
  include Thor::Actions

  desc 'model NAME COMPONENT', 'Creates a model named NAME in the component named COMPONENT'
  method_option :name, type: :string, banner: 'The name of the model.'
  method_option :component, type: :string, default: 'main', banner: 'The component the model should be created in.', required: false
  def model(name, component = 'main')
    output_file = Dir.pwd + "/app/#{component.underscore}/models/#{name.underscore.singularize}.rb"
    template('model/model.rb.tt', output_file, model_name: name.camelize.singularize)
  end

  desc 'component NAME', 'Creates a component named NAME in the app folder.'
  method_option :name, type: :string, banner: 'The name of the component.'
  def component(name)
    name = name.underscore
    component_folder = Dir.pwd + "/app/#{name}"
    component_spec_folder = Dir.pwd + '/spec/app/' + name
    @component_name = name
    directory('component', component_folder, component_name: name)
    directory('component_specs', component_spec_folder, component_name: name)
  end


  desc 'gem GEM', 'Creates a component gem where you can share a component'
  method_option :bin, type: :boolean, default: false, aliases: '-b', banner: 'Generate a binary for your library.'
  method_option :test, type: :string, lazy_default: 'rspec', aliases: '-t', banner: "Generate a test directory for your library: 'rspec' is the default, but 'minitest' is also supported."
  method_option :edit, type: :string, aliases: '-e',
                       lazy_default: [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find { |e| !e.nil? && !e.empty? },
                       required: false, banner: '/path/to/your/editor',
                       desc: 'Open generated gemspec in the specified editor (defaults to $EDITOR or $BUNDLER_EDITOR)'

  def gem(name)
    require 'volt/cli/new_gem'

    if name =~ /[-]/
      Volt.logger.error("Gem names should use underscores for their names.  Currently volt only supports a single namespace for a compoennt.")
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
    name = name.pluralize + '_controller' unless name =~ /_controller$/

    output_file = Dir.pwd + "/app/#{component}/controllers/server/#{name.underscore}.rb"
    template('controller/http_controller.rb.tt', output_file, component_module: component.camelize, http_controller_name: name.camelize)
  end

  desc 'controller NAME COMPONENT', 'Creates a model controller named NAME in the app folder of the component named COMPONENT.'
  method_option :name, type: :string, banner: 'The name of the model controller.'
  method_option :component, type: :string, default: 'main', banner: 'The component the controller should be created in.', required: false
  def controller(name, component = 'main')
    name = name + '_controller' unless name =~ /_controller$/
    output_file = Dir.pwd + "/app/#{component}/controllers/#{name.underscore}.rb"
    template('controller/model_controller.rb.tt', output_file, component_module: component.camelize, model_controller_name: name.camelize)
  end

  desc 'task NAME COMPONENT', 'Creates a task named NAME in the app folder of the component named COMPONENT.'
  method_option :name, type: :string, banner: 'The name of the task.'
  method_option :component, type: :string, default: 'main', banner: 'The component the task should be created in.', required: false
  def task(name, component = 'main')
    output_file = Dir.pwd + "/app/#{component}/tasks/#{name.underscore.singularize}.rb"
    template('task/task.rb.tt', output_file, task_name: name.camelize.singularize)
  end

  desc 'view NAME COMPONENT', 'Creates a view named NAME in the app folder of the component named COMPONENT.'
  method_option :name, type: :string, banner: 'The name of the view.'
  method_option :component, type: :string, default: 'main', banner: 'The component the view should be created in.', required: false
  def view(name, component = 'main')
    output_file = Dir.pwd + "/app/#{component}/views/#{component}/#{name.underscore.singularize}.html"
    controller(name, component) unless controller?(name, component)
    template('view/view.rb.tt', output_file, view_name: name.camelize.singularize)
  end

  private
  def controller?(name, component = 'main')
    dir = Dir.pwd + "/app/#{component}/controllers/"
    File.exists?(dir + name.downcase.underscore.singularize + '.rb')
  end
end
