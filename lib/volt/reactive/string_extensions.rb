class String
  include ReactiveTags

  alias :__old_plus :+
  if RUBY_PLATFORM != 'opal'
    alias :__old_concat :<<
  end
  # alias :concat :__old_concat

  # In volt, we want a value + reactive strings to return a reactive string.  So we
  # over-ride + to check for when we are adding a reactive string to a string.
  def +(val)
    result = __old_plus(val.cur)
    if val.reactive? && !result.reactive?
      result = ReactiveValue.new(result)
    end

    return result
  end

  if RUBY_PLATFORM != 'opal'
    def <<(val)
      if val.reactive?
        raise "Cannot append a reactive string to non-reactive string.  Use + instead"
      end
      result = __old_concat(val)

      return result
    end
  end
end
