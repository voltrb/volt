class Array
  alias :__old_plus :+

  def +(val)
    result = __old_plus(val.cur)
    if val.reactive? && !result.reactive?
      result = ReactiveValue.new(result)
    end

    return result
  end
end
