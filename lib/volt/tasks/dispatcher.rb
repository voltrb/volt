# require 'ruby-prof'
require 'volt/utils/logging/task_logger'
require 'drb'
require 'concurrent'
require 'timeout'

module Volt
  # The task dispatcher is responsible for taking incoming messages
  # from the socket channel and dispatching them to the proper handler.
  class Dispatcher
    # When we pass the dispatcher over DRb, don't send a copy, just proxy.
    include DRb::DRbUndumped

    attr_reader :volt_app

    def initialize(volt_app)
      @volt_app = volt_app

      if Volt.env.test?
        # When testing, we want to run immediately so it blocks and doesn't
        # start the next thread.
        @worker_pool = Concurrent::ImmediateExecutor.new
      else
        @worker_pool = Concurrent::ThreadPoolExecutor.new(
          min_threads: Volt.config.min_worker_threads,
          max_threads: Volt.config.max_worker_threads
        )
      end

      @worker_timeout = Volt.config.worker_timeout || 60
    end

    # Mark the last time of the component modification for caching in sprockets
    def self.component_modified(time)
      @last_modified_time = time
    end

    def component_modified(time)
      self.class.component_modified(time)
    end

    def self.component_last_modified_time
      unless @last_modified_time
        component_modified(Time.now.to_i.to_s)
      end

      @last_modified_time
    end

    # Dispatch takes an incoming Task from the client and runs it on the
    # server, returning the result to the client.
    # Tasks returning a promise will wait to return.
    def dispatch(channel, message)
      # Dispatch the task in the worker pool.  Pas in the meta data
      @worker_pool.post do
        begin
          dispatch_in_thread(channel, message)
        rescue => e
          err = "Worker Thread Exception for #{message}\n"
          err += e.inspect
          err += e.backtrace.join("\n") if e.respond_to?(:backtrace)

          Volt.logger.error(err)
        end
      end
    end


    # Check if it is safe to use this method
    def safe_method?(klass, method_name)
      # Make sure the class being called is a Task.
      return false unless klass.ancestors.include?(Task)

      # Make sure the method is defined on the klass we're using and not up the hiearchy.
      #   ^ This check prevents methods like #send, #eval, #instance_eval, #class_eval, etc...
      klass.ancestors.each do |ancestor_klass|
        if ancestor_klass.instance_methods(false).include?(method_name)
          return true
        elsif ancestor_klass == Task
          # We made it to Task and didn't find the method, that means it
          # was defined above Task, so we reject the call.
          return false
        end
      end

      false
    end

    def close_channel(channel)
      QueryTasks.new(@volt_app, channel).close!
    end

    private

    # Do the actual dispatching, should be running inside of a worker thread at
    # this point.
    def dispatch_in_thread(channel, message)
      callback_id, class_name, method_name, meta_data, *args = message
      method_name = method_name.to_sym

      # Get the class
      klass = Object.send(:const_get, class_name)

      promise = Promise.new
      cookies = nil

      start_time = Time.now.to_f

      # Check that we are calling on a Task class and a method provide at
      # Task or above in the ancestor chain. (so no :send or anything)
      if safe_method?(klass, method_name)
        promise.resolve(nil)

        # Init and send the method
        promise = promise.then do
          result = nil
          Timeout.timeout(klass.__timeout || @worker_timeout) do
            Thread.current['meta'] = meta_data
            begin
              klass_inst = klass.new(@volt_app, channel, self)
              result = klass_inst.send(method_name, *args)
              cookies = klass_inst.fetch_cookies
            ensure
              Thread.current['meta'] = nil
            end
          end

          result
        end

      else
        # Unsafe method
        promise.reject(RuntimeError.new("unsafe method: #{method_name}"))
      end

      # Called after task runs or fails
      finish = proc do |error|
        if error.is_a?(Timeout::Error)
          # re-raise with a message
          error = Timeout::Error.new("Task Timed Out after #{@worker_timeout} seconds: #{message}")
        end

        run_time = ((Time.now.to_f - start_time) * 1000).round(3)
        Volt.logger.log_dispatch(class_name, method_name, run_time, args, error)
      end

      # Run the promise and pass the return value/error back to the client
      promise.then do |result|
        reply = EJSON.stringify(['response', callback_id, result, nil, cookies])
        channel.send_string_message(reply)

        finish.call
      end.fail do |error|
        begin
          finish.call(error)

          begin
            # Try to send, handle error if we can't convert the result to EJSON
            reply = EJSON.stringify(['response', callback_id, nil, error, cookies])

            # use send_string_message, since we stringify here, not on the other
            # side of Drb.
            channel.send_string_message(reply)
          rescue EJSON::NonEjsonType => e
            # Convert the error into a string so it can be serialized to
            # something.
            error = "#{error.class.to_s}: #{error.to_s}"
            channel.send_message('response', callback_id, nil, error, cookies)
          end

        rescue => e
          Volt.logger.error "Error in fail dispatch: #{e.inspect}"
          Volt.logger.error(e.backtrace.join("\n")) if e.respond_to?(:backtrace)
          raise
        end
      end

    end
  end
end
