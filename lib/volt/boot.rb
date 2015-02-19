require 'volt/models'
require 'volt/server/rack/component_paths'
if RUBY_PLATFORM == 'opal'
  require 'volt'
else
  require 'volt/page/page'
end

module Volt
  def self.boot(app_path)
    # Run the app config to load all users config files
    unless RUBY_PLATFORM == 'opal'
      Volt.run_files_in_config_folder

      if Volt.server?
        $page = Page.new
      end
    end

    component_paths = ComponentPaths.new(app_path)
    component_paths.require_in_components

    component_paths
  end
end
