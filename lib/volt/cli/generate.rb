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
    @component_name = name
    directory('component', component_folder, component_name: name)
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

    NewGem.new(self, name, options)
  end

  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), '../../../templates'))
  end
end
