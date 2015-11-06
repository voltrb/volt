#

require 'drb'
require 'stringio'
require 'listen'

class ErrorDispatcher
  def dispatch(channel, message)
    Volt.logger.error("The app failed to start, so the following message can not be run: #{message}")
  end

  def close_channel(channel)
  end
end

module Volt
  class ForkingServer
    def initialize(server)
      # A read write lock for accessing and creating the lock
      @child_lock = ReadWriteLock.new

      # Trap exit
      at_exit do
        # Only run on parent
        if @child_id
          puts 'Exiting...'
          @exiting = true
          stop_child
        end
      end

      @server = server

      # Set the mod time on boot
      update_mod_time

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

          watch_for_parent_exit

          begin
            volt_app = @server.boot_volt
            @rack_app = volt_app.middleware

            # Set the drb object locally
            @dispatcher = Dispatcher.new(volt_app)
          rescue Exception => error
            boot_error(error)
          end


          drb_object = DRb.start_service('drbunix:', [self, @dispatcher])

          @writer.puts(drb_object.uri)

          begin
            DRb.thread.join
          rescue Interrupt => e
            # Ignore interrupt
            exit
          end
        end
      end
    end

    # called from the child when the boot failes.  Sets up an error page rack
    # app to show the user the error and handle reloading requests.
    def boot_error(error)
      msg = error.inspect
      if error.respond_to?(:backtrace)
        msg << "\n" + error.backtrace.join("\n")
      end
      Volt.logger.error(msg)

      # Only require when needed
      require 'cgi'
      @rack_app = Proc.new do
        path = File.join(File.dirname(__FILE__), "forking_server/boot_error.html.erb")
        html = File.read(path)
        error_page = ERB.new(html, nil, '-').result(binding)

        [500, {"Content-Type" => "text/html"}, error_page]
      end

      @dispatcher = ErrorDispatcher.new
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

    # In the even the parent gets killed without at_exit running,
    # we watch the pipe and close if the pipe gets closed.
    def watch_for_parent_exit
      Thread.new do
        loop do
          if @writer.closed?
            puts 'Parent process died'
            exit
          end

          sleep 3
        end
      end
    end

    # When passing an object, Drb will not marshal it if any of its subobjects
    # are not marshalable.  So we split the marshable and not marshalbe objects
    # then re-merge them so we get real copies of most values (which are
    # needed in some cases)  Then we merge them back into a new hash.
    def call_on_child(env_base, env_other)
      env = env_base

      # TODO: this requires quite a few trips, there's probably a faster way
      # to handle this.
      env_other.each_pair do |key, value|
        env[key] = value
      end

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
          env_base = {}
          env_other = {}

          env.each_pair do |key, value|
            if [String, TrueClass, FalseClass, Array].include?(value.class)
              env_base.merge!(key => value)
            else
              env_other.merge!(key => value)
            end
          end

          status, headers, body_str = @server_proxy.call_on_child(env_base, env_other)

          [status, headers, StringIO.new(body_str)]
        end
      end
    end


    def reload(changed_files)
      # only reload the server code if a non-view file was changed
      server_code_changed = changed_files.any? { |path| File.extname(path) == '.rb' }

      msg = 'file changed, reloading'
      msg << ' server and' if server_code_changed
      msg << ' client...'

      Volt.logger.log_with_color(msg, :light_blue)


      # Figure out if any views or routes were changed:
      # TODO: Might want to only check for /config/ under the CWD
      if changed_files.any? {|path| path =~ /\/config\// }
        update_mod_time
        sync_mod_time
      end

      begin
        SocketConnectionHandler.send_message_all(nil, 'reload')
      rescue => e
        Volt.logger.error('Reload dispatch error: ')
        Volt.logger.error(e)
      end

      if server_code_changed
        @child_lock.with_write_lock do
          stop_child
          start_child
          sync_mod_time
        end
      end
    end

    def update_mod_time
      @last_mod_time = Time.now.to_i.to_s
    end

    def sync_mod_time
      disp = SocketConnectionHandler.dispatcher

      unless disp.is_a?(ErrorDispatcher)
        disp.component_modified(@last_mod_time)
      end
    end

    def start_change_listener
      sync_mod_time

      options = {}
      if ENV['POLL_FS']
        options[:force_polling] = true
      end

      # Setup the listeners for file changes
      @listener = Listen.to("#{@server.app_path}/", options) do |modified, added, removed|
        Thread.new do
          # Run the reload in a new thread
          reload(modified + added + removed)
        end
      end
      @listener.start
    end

    def stop_change_listener
      @listener.stop
    end
  end
end
