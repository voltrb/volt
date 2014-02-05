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
    when 'added'
      added(*args)
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
  
  def added(path, data)
    $loading_models = true
    
    # Don't add if already in there
    # TODO: shouldn't send twice
    unless Persistors::ModelStore.from_id(data[:_id])
    
      _, parent_id = data.find {|k,v| k != :_id && k[-3..-1] == '_id'}
      if parent_id
        parent_collection = Persistors::ModelStore.from_id(parent_id).model
      else
        # On the root
        parent_collection = $page.store
      end
    
      puts "From Backend: Add: #{path.inspect} - #{data.inspect}"
      parent_collection.send(path) << data
    end
    $loading_models = false
  end
  
  def removed(id)
    puts "From Backend: Remove: #{id}"
    $loading_models = true
    model = Persistors::ModelStore.from_id(id)
    model.delete!
    $loading_models = false
  end
  
  # Called when the results of a query are changed, or on initial load
  def updated(collection, query, data)
    puts "UPDATED: #{collection.inspect} - #{query.inspect} - #{data.inspect}"
    Persistors::ArrayStore.updated(collection, query, data)
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