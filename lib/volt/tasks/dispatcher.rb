module Volt
  # The task dispatcher is responsible for taking incoming messages
  # from the socket channel and dispatching them to the proper handler.
  class Dispatcher
    def dispatch(channel, message)
      callback_id, class_name, method_name, *args = message
      method_name = method_name.to_sym

      # Get the class
      klass = Object.send(:const_get, class_name)

      result = nil
      error = nil

      if safe_method?(klass, method_name)
        # Init and send the method
        begin
          result = klass.new(channel, self).send(method_name, *args)
        rescue => e
          # TODO: Log these errors better
          puts e.inspect
          puts e.backtrace
          error = e
        end
      else
        # Unsafe method
        error = RuntimeError.new("unsafe method: #{method_name}")
      end

      if callback_id
        # Callback with result
        channel.send_message('response', callback_id, result, error)
      end
    end

    # Check if it is safe to use this method
    def safe_method?(klass, method_name)
      # Make sure the class being called is a TaskHandler.
      return false unless klass.ancestors.include?(TaskHandler)

      # Make sure the method is defined on the klass we're using and not up the hiearchy.
      #   ^ This check prevents methods like #send, #eval, #instance_eval, #class_eval, etc...
      klass.ancestors.each do |ancestor_klass|
        if ancestor_klass.instance_methods(false).include?(method_name)
          return true
        elsif ancestor_klass == TaskHandler
          # We made it to TaskHandler and didn't find the method, that means it
          # was defined above TaskHandler, so we reject the call.
          return false
        end
      end

      return false
    end
  end
end
