# The task dispatcher is responsible for taking incoming messages
# from the socket channel and dispatching them to the proper handler.
class Dispatcher

  def dispatch(channel, message)
    callback_id, class_name, method_name, *args = message

    # TODO: Think about security?
    if class_name[/Tasks$/] && !class_name['::']
      # TODO: Improve error on a class we don't have
      require(class_name.underscore)

      # Get the class
      klass = Object.send(:const_get, class_name)

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
