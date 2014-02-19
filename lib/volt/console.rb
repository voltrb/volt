class Console
  def self.start
    require 'pry'

    $LOAD_PATH << 'lib'
    ENV['SERVER'] = 'true'

    require 'volt'
    require 'volt/models'
    require 'volt/server/template_parser'
    require 'volt'
    require 'volt/page/page'
    require 'volt/server/rack/component_paths'
    require 'volt/server/socket_connection_handler_stub'

    SocketConnectionHandlerStub.dispatcher = Dispatcher.new


    app_path = File.expand_path(File.join(Dir.pwd, "app"))
    component_paths = ComponentPaths.new
    component_paths.require_in_components

    Pry.config.prompt_name = 'volt'

    # start a REPL session
    # Pry.start

    Page.new.pry
  end
end
