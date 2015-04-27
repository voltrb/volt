#

require 'drb'
require 'stringio'
require 'listen'

module Volt
  class ForkingServer
    def initialize(server)
      # A read write lock for accessing and creating the lock
      @child_lock = ReadWriteLock.new

      # Trap exit
      at_exit do
        # Only run on parent
        if @child_id
          puts "Exiting..."
          @exiting = true
          stop_child
        end
      end

      @server = server

      start_child
    end

    # Start child forks off a child process and sets up a DRb connection to the
    # child.  #start_child should be called from within the write lock.
    def start_child
      # Aquire the write lock, so we prevent anyone from using the child until
      # its setup or recreated.
      unless @drb_object
        # Get the id of the parent process, so we can wait for exit in the child
        # so the child can exit if the parent closes.
        @parent_id = Process.pid

        @reader, @writer = IO.pipe

        if @child_id = fork
          # running as parent
          @writer.close

          # Read the url from the child
          uri = @reader.gets.strip

          # Setup a drb object to the child
          DRb.start_service

          @drb_object = DRbObject.new_with_uri(uri)
          @server_proxy = @drb_object[0]
          @dispatcher_proxy = @drb_object[1]

          SocketConnectionHandler.dispatcher = @dispatcher_proxy

          start_change_listener
        else
          # Running as child
          @reader.close

          @server.boot_volt
          @rack_app = @server.new_server

          # Set the drb object locally
          @dispatcher = Dispatcher.new
          drb_object = DRb.start_service(nil, [self, @dispatcher])

          @writer.puts(drb_object.uri)

          watch_for_parent_exit

          begin
            DRb.thread.join
          rescue Interrupt => e
            # Ignore interrupt
            exit
          end
        end
      end
    end

    # In the even the parent gets killed without at_exit running,
    # we watch the pipe and close if the pipe gets closed.
    def watch_for_parent_exit
      Thread.new do
        loop do
          if @writer.closed?
            puts "Parent process died"
            exit
          end

          sleep 3
        end
      end
    end

    def call_on_child(env)
      status, headers, body = @rack_app.call(env)

      # Extract the body to pass as a string.  We need to do this
      # because after the call, the objects will be GC'ed, so we want
      # them to be able to be marshaled to be send over DRb.
      if body.respond_to?(:to_str)
        body_str = body
      else
        extracted_body = []

        # Read the
        body.each do |str|
          extracted_body << str
        end

        body.close if body.respond_to?(:close)
        body_str = extracted_body.join
      end

      [status, headers, body_str]
    end

    def call(env)
      @child_lock.with_read_lock do
        if @exiting
          [500, {}, 'Server Exiting']
        else
          @server_proxy.call_on_child(env)
        end
      end
    end

    def stop_child
      # clear the drb object and kill the child process.
      if @drb_object
        begin
          @drb_object = nil
          DRb.stop_service
          @reader.close
          stop_change_listener
          Process.kill(9, @child_id)
        rescue => e
          puts "Stop Child Error: #{e.inspect}"
        end
      end
    end

    def reload
      Volt.logger.log_with_color('file changed, sending reload', :light_blue)
      begin
        SocketConnectionHandler.send_message_all(nil, 'reload')
      rescue => e
        Volt.logger.error("Reload dispatch error: ")
        Volt.logger.error(e)
      end

      @child_lock.with_write_lock do
        stop_child
        start_child
      end
    end

    def start_change_listener
      # Setup the listeners for file changes
      @listener = Listen.to("#{@server.app_path}/") do |modified, added, removed|
        Thread.new do
          # Run the reload in a new thread
          reload
        end
      end
      @listener.start
    end

    def stop_change_listener
      @listener.stop
    end

  end
end