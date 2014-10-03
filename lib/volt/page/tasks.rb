# The tasks class provides an interface to call tasks on
# the backend server.
class Tasks
  def initialize(page)
    @page = page
    @callback_id = 0
    @callbacks = {}

    # TODORW: ...
    page.channel.on('message') do |*args|
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
    when 'added', 'removed', 'updated', 'changed'
      notify_query(name, *args)
    when 'response'
      response(callback_id, *args)
    when 'reload'
      reload
    end
  end

  # When a request is sent to the backend, it can attach a callback,
  # this is called from the backend to pass to the callback.
  def response(callback_id, result, error)
    callback = @callbacks.delete(callback_id)

    if callback
      if error
        # TODO: full error handling
        puts "Task Response: #{error.inspect}"
      else
        callback.call(result)
      end
    end
  end

  # Called when the backend sends a notification to change the results of
  # a query.
  def notify_query(method_name, collection, query, *args)
    query_obj = Persistors::ArrayStore.query_pool.lookup(collection, query)
    query_obj.send(method_name, *args)
  end

  def reload
    # Stash the current page value
    value = JSON.dump($page.page.to_h)

    # If this browser supports session storage, store the page, so it will
    # be in the same state when we reload.
    if `sessionStorage`
      `sessionStorage.setItem('___page', value);`
    end

    $page.page._reloading = true
    `window.location.reload(false);`
  end
end
