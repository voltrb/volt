module Volt
  # The task dispatcher is responsible for taking incoming messages
  # from the socket channel and dispatching them to the proper handler.
  class Dispatcher
    def dispatch(channel, message)
      callback_id, class_name, method_name, *args = message

      # Get the class
      klass = Object.send(:const_get, class_name)

      # Make sure the class being called is a TaskHandler.
      # Make sure the method is defined on the klass we're using and not up the hiearchy.
      #   ^ This check prevents methods like #send, #eval, #instance_eval, #class_eval, etc...
      if klass.is_a?(TaskHandler) && klass.instance_methods(false).include?(method_name)
        # Init and send the method
        begin
          result = klass.new(channel, self).send(method_name, *args)
          error = nil
        rescue => e
          # TODO: Log these errors better
          puts e.inspect
          puts e.backtrace
          result = nil
          error = e
        end

        if callback_id
          # Callback with result
          channel.send_message('response', callback_id, result, error)
        end
      end
    end
  end
end
