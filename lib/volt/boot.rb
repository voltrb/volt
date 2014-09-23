require 'volt/models'
require 'volt/server/rack/component_paths'
require 'volt/page/page'

class Volt
  def self.boot(app_path)
    component_paths = ComponentPaths.new(app_path)
    component_paths.require_in_components

    return component_paths
  end
end