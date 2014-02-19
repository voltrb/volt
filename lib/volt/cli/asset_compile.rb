class CLI

  desc "precompile", "precompile all application assets"
  def precompile
    require 'volt'
    require 'volt/server/rack/component_paths'
    require 'volt/server/component_templates'

    home_component = ComponentPaths.new(Volt.root).components['home']
    component_templates = ComponentTemplates.new(home_component.first, 'home')
    code = component_templates.code
  end

end