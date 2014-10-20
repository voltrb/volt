class Numeric
  def in_units_of(unit)
    if self == 1
      return "1 #{unit}"
    else
      return "#{self} #{unit}s"
    end
  end
end
