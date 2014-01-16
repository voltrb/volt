# The task dispatcher is responsible for taking incoming messages
# from the socket channel and dispatching them to the proper handler.
class Dispatcher
  def dispatch(message)
    class_name, method_name, *args = message
    
    
  end
end