class Array
  def sum
    total = 0
    self.each do |val|
      total += val
    end

    return total
  end
end
