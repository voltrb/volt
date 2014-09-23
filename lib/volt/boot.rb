require 'volt/models'
require 'volt/server/rack/component_paths'
if RUBY_PLATFORM == 'opal'
  require 'volt'
else
  require 'volt/page/page'
end

class Volt
  def self.boot(app_path)
    component_paths = ComponentPaths.new(app_path)
    component_paths.require_in_components

    return component_paths
  end
end