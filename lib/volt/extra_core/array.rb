class Array
  def sum
    inject(0, :+)
  end

  # For some reason .to_h doesn't show as defined in opal, but defined?(:to_h)
  # returns true.
  def to_h
    Hash[self]
  end
end
