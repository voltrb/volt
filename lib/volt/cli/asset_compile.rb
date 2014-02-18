class CLI
  
  desc "precompile", "precompile all application assets"
  def precompile
    require 'volt'
    require 'volt/server/rack/component_paths'
    
    puts ComponentPaths.new(Volt.root).components.inspect
  end
  
end