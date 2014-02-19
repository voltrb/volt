class String
  # TODO: replace with better implementations
  # NOTE: strings are currently immutable in Opal, so no ! methods
  def camelize
    self.split("_").map {|s| s.capitalize }.join("")
  end

  def underscore
    self.scan(/[A-Z][a-z]*/).join("_").downcase
  end

  def pluralize
    # TODO: Temp implementation
    if self[-1] != 's'
      return self + 's'
    else
      return self
    end
  end

  def singularize
    # TODO: Temp implementation
    if self[-1] == 's'
      return self[0..-2]
    else
      return self
    end
  end

  def plural?
    # TODO: Temp implementation
    self[-1] == 's'
  end

  def singular?
    # TODO: Temp implementation
    self[-1] != 's'
  end
end
