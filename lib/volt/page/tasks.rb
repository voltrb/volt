# The tasks class provides an interface to call tasks on
# the backend server.
class Tasks
  def initialize(page)
    @page = page
    @callback_id = 0
    @callbacks = {}
    
    page.channel.on('message') do |_, *args|
      received_message(*args)
    end
  end
  
  def call(class_name, method_name, *args, &callback)
    if callback
      callback_id = @callback_id
      @callback_id += 1

      # Track the callback
      # TODO: Timeout on these callbacks
      @callbacks[callback_id] = callback
    else
      callback_id = nil
    end
    
    @page.channel.send_message([callback_id, class_name, method_name, *args])
  end
  
  
  def received_message(name, callback_id, *args)
    case name
    when 'response'
      response(callback_id, *args)
    when 'changed'
      changed(*args)
    when 'added'
      added(*args)
    when 'removed'
      removed(*args)
    when 'reload'
      reload
    end
  end
  
  def response(callback_id, *args)
    callback = @callbacks.delete(callback_id)
    
    if callback
      callback.call(*args)
    end
  end
  
  def changed(model_id, data)
    $loading_models = true
    puts "UPDATE: #{model_id} with #{data.inspect}"
    Store.update(model_id, data)
    $loading_models = false
  end
  
  def added(path, data)
    $loading_models = true
    puts "Add: #{path.inspect} - #{data.inspect}"
    $page.store.send(path) << data
    $loading_models = false
  end
  
  def removed(id)
    $loading_models = true
    Store.from_id(id).delete!
    $loading_models = false
  end
  
  def reload
    puts "RELOAD"
    $page.page._reloading = true
    `window.location.reload(false);`
  end
end