class Object
  # Setup a default pretty_inspect
  # alias_method :pretty_inspect, :inspect

  def instance_values
    Hash[instance_variables.map { |name| [name[1..-1], instance_variable_get(name)] }]
  end

  def html_inspect
    inspect.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  # TODO: Need a real implementation of this
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end
