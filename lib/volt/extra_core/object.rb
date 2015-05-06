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
    if RUBY_PLATFORM == 'opal'
      JSON.parse(to_json)
    else
      Marshal.load(Marshal.dump(self))
    end
  end

  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      public_send(*a, &b) if respond_to?(a.first)
    end
  end
end
