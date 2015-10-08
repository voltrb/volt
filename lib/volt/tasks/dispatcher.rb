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

    class Responder
      def initialize(channel, message)
        @start_time = Time.now.to_f
        @channel = channel
        @message = message
      end

      def update(time, value, reason)
        callback_id, class_name, method_name, meta_data, *args = @message
        result, cookies = *value

        if reason
          # Convert the reason into a string so it can be serialized.
          reason_str = "#{reason.class.to_s}: #{reason.to_s}"
          @channel.send_message('response', callback_id, nil, reason_str, cookies)
        else
          reply = EJSON.stringify(['response', callback_id, result, nil, cookies])
          @channel.send_string_message(reply)
        end

        run_time = ((Time.now.to_f - @start_time) * 1000).round(3)
        Volt.logger.log_dispatch(class_name, method_name, run_time, args, reason)
      end
    end
    private_constant :Responder

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

      # Setting timers on tasks requires two threads: one for the task and other
      # to run the timer. For efficiency we'll run all our timers on one thread.
      # But we'll handle all the tasks on the main worker pool.
      @monitor = Concurrent::TimerSet.new(executor: @worker_pool)
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
    def dispatch(channel, message)
      # Create a responder to handle the result, whatever it is.
      responder = Responder.new(channel, message)

      # Start the task on the worker pool.
      task = Concurrent::Future.new(executor: @worker_pool, args: [@volt_app, self, channel, message]) do |app, dispatcher, chan, msg|
        dispatch_in_thread(app, dispatcher, chan, msg)
      end
      task.add_observer(responder)
      task.execute

      # Set a timer to respond if the task times out.
      # Also, how do we guarantee that the timer doesn't get GCed?
      # need to get klass.__timeout from message
      Concurrent::ScheduledTask.execute(@worker_timeout,
                                        timer_set: @monitor,
                                        executor: @worker_pool,
                                        args: [task, @worker_timeout, message]) do |t, timeout, msg|
        # Does nothing if the task is already complete.
        t.fail(Timeout::Error.new("Task Timed Out after #{timeout} seconds: #{msg}"))
      end
    end

    def close_channel(channel)
      QueryTasks.new(@volt_app, channel).close!
    end

    private

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

    # Do the actual dispatching, should be running inside of a worker thread at
    # this point.
    def dispatch_in_thread(app, dispatcher, channel, message)
      callback_id, class_name, method_name, meta_data, *args = message
      method_name = method_name.to_sym

      # Get the class
      klass = Object.send(:const_get, class_name)

      cookies = nil

      # Check that we are calling on a Task class and a method provide at
      # Task or above in the ancestor chain. (so no :send or anything)
      if safe_method?(klass, method_name)

        # Init and send the method
        result = nil
        Thread.current['meta'] = meta_data
        begin
          klass_inst = klass.new(app, channel, dispatcher)
          result = klass_inst.send(method_name, *args)
          cookies = klass_inst.fetch_cookies
        ensure
          Thread.current['meta'] = nil
        end

        return result, cookies
      else
        raise RuntimeError.new("unsafe method: #{method_name}")
      end
    end
  end
end
