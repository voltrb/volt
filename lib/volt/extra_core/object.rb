class Object
  # Setup a default pretty_inspect
  # alias_method :pretty_inspect, :inspect

  def instance_values
    Hash[instance_variables.map { |name| [name[1..-1], instance_variable_get(name)] }]
  end

  # Provides the same functionality as ||, but since ReactiveValue's only
  # work with method calls, we provide .or as a convience.
  def or(other)
    if self && !self.nil?
      return self
    else
      return other
    end
  end

  # Provides the same functionality as &&, but since ReactiveValue's only
  # work with method calls, we provide .and as a convience
  def and(other)
    if self && !self.nil?
      return other
    else
      return self
    end
  end

  def html_inspect
    inspect.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  # TODO: Need a real implementation of this
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end
