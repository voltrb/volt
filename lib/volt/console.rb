class Console
  def self.start
    require 'pry'

    $LOAD_PATH << 'lib'
    ENV['SERVER'] = 'true'

    require 'volt/extra_core/extra_core'
    require 'volt/models'
    require 'volt/models/params'
    require 'volt/server/template_parser'
    require 'volt'
    require 'volt/page/page'
    require 'volt/server/rack/component_paths'
    require 'volt/server/channel_handler_stub'
    
    ChannelHandlerStub.dispatcher = Dispatcher.new
    
        
    app_path = File.expand_path(File.join(Dir.pwd, "app"))
    component_paths = ComponentPaths.new
    component_paths.setup_components_load_path

    Pry.config.prompt_name = 'volt'

    # start a REPL session
    # Pry.start
    
    Page.new.pry
  end
end