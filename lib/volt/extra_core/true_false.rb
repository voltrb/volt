# The true?/false? predicates are convience methods since if ..reactive_value.. does
# not correctly evaluate.  The reason for this is that ruby currently does not allow
# anything besides nil and false to be falsy.

class Object
  def true?
    true
  end

  def false?
    false
  end
end

class FalseClass
  def true?
    false
  end

  def false?
    true
  end
end

class NilClass
  def true?
    false
  end

  def false?
    true
  end
end

# Opal only has a single class for true/false
class Boolean
  def true?
    self
  end

  def false?
    self
  end
end
