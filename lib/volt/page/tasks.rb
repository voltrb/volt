require 'volt/utils/ejson'

module Volt
  # The tasks class provides an interface to call tasks on
  # the backend server.  This class is setup as page.task (as a singleton)
  class Tasks
    def initialize(volt_app)
      @volt_app       = volt_app
      @promise_id = 0
      @promises   = {}

      volt_app.channel.on('message') do |*args|
        received_message(*args)
      end
    end

    def call(class_name, method_name, meta_data, *args)
      promise_id            = @promise_id
      @promise_id += 1

      # Track the callback
      promise               = Promise.new
      @promises[promise_id] = promise

      # TODO: Timeout on these callbacks
      @volt_app.channel.send_message([promise_id, class_name, method_name, meta_data, *args])

      promise
    end

    def received_message(name, promise_id, *args)
      case name
        when 'added', 'removed', 'updated', 'changed'
          notify_query(name, *args)
        when 'response'
          response(promise_id, *args)
        when 'reload'
          reload
      end
    end

    # When a request is sent to the backend, it can attach a callback,
    # this is called from the backend to pass to the callback.
    def response(promise_id, result, error, cookies)
      # Set the cookies
      if cookies
        cookies.each do |key, value|
          @volt_app.cookies.set(key, value)
        end
      end

      promise = @promises.delete(promise_id)

      if promise
        if error
          # TODO: full error handling
          Volt.logger.error('Task Response:')
          Volt.logger.error(error)

          promise.reject(error)
        else
          promise.resolve(result)
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
      begin
        value = EJSON.stringify(Volt.current_app.page.to_h)

        # If this browser supports session storage, store the page, so it will
        # be in the same state when we reload.
        `sessionStorage.setItem('___page', value);` if `sessionStorage`
      rescue EJSON::NonEjsonType => e
        # Unable to serailize the page, ignore stashing it
        # clear the ___page stash
        `sessionStorage.removeItem('___page');`
      end

      Volt.current_app.page._reloading = true
      `window.location.reload(false);`
    end
  end
end
