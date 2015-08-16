class Array
  def sum
    inject(0, :+)
  end

  # For some reason .to_h doesn't show as defined in opal, but defined?(:to_h)
  # returns true.
  def to_h
    Hash[self]
  end


  # Converts an array to a sentence
  def to_sentence(options={})
    conjunction = options.fetch(:conjunction, 'and')
    comma       = options.fetch(:comma, ',')
    oxford      = options.fetch(:oxford, true) # <- true is the right value

    case size
    when 0
      ''
    when 1
      self[0].to_s
    when 2
      self.join(" #{conjunction} ")
    else
      str = self[0..-2].join(comma + ' ')
      str += comma if oxford
      str += " #{conjunction} " + self[-1].to_s
      str
    end
  end
end
