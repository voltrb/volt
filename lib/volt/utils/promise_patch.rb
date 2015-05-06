# A temp patch for promises until https://github.com/opal/opal/pull/725 is released.
class Promise
  def initialize(success = nil, failure = nil)
    @success = success
    @failure = failure

    @realized  = nil
    @exception = false
    @value     = nil
    @error     = nil
    @delayed   = false

    @prev = nil
    @next = nil
  end

  def method_missing(method_name, *args, &block)
    self.then do |result|
      result.send(method_name.to_sym, *args, &block)
    end.fail do |error|
      raise error
    end
  end

  def >>(promise)
    @next = promise

    if exception?
      promise.reject(@delayed[0])
    elsif resolved?
      promise.resolve(@delayed ? @delayed[0] : value)
    elsif rejected? && (!@failure || Promise === (@delayed ? @delayed[0] : @error))
      promise.reject(@delayed ? @delayed[0] : error)
    end

    self
  end

  def resolve!(value)
    if @next
      @next.resolve(value)
    else
      @delayed = [value]
    end
  end

  def reject!(value)
    if @next
      @next.reject(value)
    else
      @delayed = [value]
    end
  end

  # Waits for the promise to resolve (assuming it is blocking on
  # the server) and returns the result.
  def sync
    result = nil
    error = nil

    self.then do |val|
      result = val
    end.fail do |err|
      error = err
    end

    if error
      raise error
    else
      return result
    end
  end
end
