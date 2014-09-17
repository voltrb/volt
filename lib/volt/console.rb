require 'pry'

class Pry
  # To make the console more useful, we make it so we flush the event registry
  # after each line.  This makes it so events are triggered after each line.
  # To accomplish this we monkey-patch pry.
  def rep(target=TOPLEVEL_BINDING)
    target = Pry.binding_for(target)
    result = re(target)

    Pry.critical_section do
      show_result(result)
    end

    # Automatically flush after each line
    Dependency.flush!
  end
end


class Console
  def self.start
    require 'pry'

    $LOAD_PATH << 'lib'
    ENV['SERVER'] = 'true'

    require 'volt'
    require 'volt/models'
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
    Pry.start

    # Page.new.pry
  end
end
