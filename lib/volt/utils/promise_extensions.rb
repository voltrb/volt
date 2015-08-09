# A temp patch for promises until https://github.com/opal/opal/pull/725 is released.
class Promise
  class UnrealizedPromiseException < RuntimeError ; end
  # We made a choice not to support comparitors and << and >> on method_missing
  # on Promises.  This makes it easier to understand what promise proxying does
  # and how it works.  It also prevents confusing situations where you try to
  # == compare two Promises for example.  The cost though is more code to do
  # comparisons, but we feel it is worth it.
  def respond_to_missing?(method_name, include_private = false)
    !!(method_name =~ /[a-z_]\w*[?!=]?/)
  end

  def method_missing(method_name, *args, &block)
    if respond_to_missing?(method_name)
      promise = self.then do |value|
        value.send(method_name, *args, &block)
      end

      promise
    else
      super
    end
  end

  # Allow .each to be called directly on promises
  def each(&block)
    raise ArgumentError, 'no block given' unless block

    self.then do |val|
      val.each(&block)
    end
  end

  # Improve #inspect to not show nested promises.
  def inspect
    result = "#<#{self.class}(#{object_id})"

    if @next
      result += " >> #{@next.inspect}"
    end

    if realized?
      value = value_or_error

      loop do
        if value.is_a?(Promise) && value.realized?
          value = value.value_or_error
        else
          break
        end
      end

      result += ": #{value.inspect}>"
    else
      result += ">"
    end

    result
  end

  def value_or_error
    @value || @error
  end

  # When testing with rspec, add in a custom exception! method that doesn't
  # swallow ExpectationNotMetError's.
  if defined?(RSpec) && defined?(RSpec::Expectations::ExpectationNotMetError)
    def exception!(error)
      if error.is_a?(RSpec::Expectations::ExpectationNotMetError)
        raise error
      end
      @exception = true

      reject!(error)
    end
  end

  # Forward to resolved value
  def to_json(*args, &block)
    self.then {|v| v.to_json(*args, &block) }
  end

  # unwrap lets you return a value or raise an exceptoin on a realized promise.
  # An exception will be raised if the promise is not realized yet.
  def unwrap
    if realized?
      if resolved?
        value
      else
        Object.send(:fail, error)
      end
    else
      raise UnrealizedPromiseException, "#unwrap called on a promise that has yet to be realized."
    end
  end

  # Waits for the promise to be realized (resolved or rejected), then returns
  # the resolved value or raises the rejection error.  .sync only works on
  # the server (not in opal), and will raise a warning if on the client.
  def sync
    raise ".sync can only be used on the server" if Volt.client?

    result = nil
    error = nil

    self.then do |val|
      result = val
    end.fail do |err|
      error = err
    end

    if error
      if error.is_a?(RSpec::Expectations::ExpectationNotMetError)
        # re-raise
        raise error
      end
      err_str = "Exception in Promise at .sync: #{error.inspect}"
      err_str += error.backtrace.join("\n") if error.respond_to?(:backtrace)
      Volt.logger.error(err_str)

      # The fail method in Promise is already defined, to re-raise the error,
      # we send fail
      Object.send(:fail, error)
    else
      return result
    end
  end
end
