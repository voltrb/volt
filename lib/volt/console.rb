class Console
  def self.start
    require 'pry'

    $LOAD_PATH << 'lib'
    ENV['SERVER'] = 'true'

    require 'volt'
    require 'volt/boot'
    require 'volt/server/socket_connection_handler_stub'

    SocketConnectionHandlerStub.dispatcher = Dispatcher.new

    Volt.boot(Dir.pwd)

    Pry.config.prompt_name = 'volt'

    # start a REPL session
    # Pry.start

    Page.new.pry
  end
end
