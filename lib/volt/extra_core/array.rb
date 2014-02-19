class Array
  def sum
    total = 0
    self.each do |val|
      total += val
    end

    return total
  end

  def deep_cur
    new_array = []
    each do |item|
      new_array << item.deep_cur
    end

    return new_array
  end
end
