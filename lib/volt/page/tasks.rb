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
    puts "GOT: #{name} - #{args.inspect}"
    case name
    when 'response'
      response(callback_id, *args)
    when 'changed'
      changed(*args)
    when 'added', 'removed', 'updated'
      notify_query(name, *args)
    when 'removed'
      removed(*args)
    when 'updated'
      updated(*args)
    when 'reload'
      reload
    end
  end
  
  def response(callback_id, result, error)
    callback = @callbacks.delete(callback_id)
    
    if callback
      if error
        # TODO: full error handling
        puts "Error: #{error.inspect}"
      else
        callback.call(result)
      end
    end
  end
  
  def changed(model_id, data)
    $loading_models = true
    puts "From Backend: UPDATE: #{model_id} with #{data.inspect}"
    Persistors::ModelStore.update(model_id, data)
    $loading_models = false
  end
  

  
  # Called when the backend sends a notification to change the results of
  # a query.
  def notify_query(method_name, collection, query, *args)
    query_obj = Persistors::ArrayStore.query_pool.lookup(collection, query)
    query_obj.send(method_name, *args)
  end
  
  def reload
    puts "RELOAD"
    # Stash the current page value
    value = JSON.dump($page.page.cur.to_h.reject {|k,v| v.reactive? })
    
    # If this browser supports session storage, store the page, so it will
    # be in the same state when we reload.
    if `sessionStorage`
      `sessionStorage.setItem('___page', value);`
    end
    
    $page.page._reloading = true
    `window.location.reload(false);`
  end
end