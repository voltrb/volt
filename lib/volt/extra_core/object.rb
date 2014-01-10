class Object
  # Setup a default pretty_inspect
  # alias_method :pretty_inspect, :inspect
  
  def instance_values
    Hash[instance_variables.map { |name| [name[1..-1], instance_variable_get(name)] }]
  end
  
  # Provides the same functionality as ||, but since ReactiveValue's only
  # work with method calls, we provide .or as a convience.
  def or(other)
    if self.true?
      return self
    else
      return other
    end
  end
  
  # Provides the same functionality as &&, but since ReactiveValue's only
  # work with method calls, we provide .and as a convience
  def and(other)
    if self.true?
      return other
    else
      return self
    end
  end
  
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end
end