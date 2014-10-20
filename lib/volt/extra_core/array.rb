class Array
  def sum
    total = 0
    each do |val|
      total += val
    end

    total
  end
end
