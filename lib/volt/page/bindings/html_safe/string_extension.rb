class String
  def html_safe
    # Convert to a real string (opal uses native strings normally, so wrap so we can
    # use instance variables)
    str = String.new(self)
    str.instance_variable_set('@html_safe', true)
    str
  end

  def html_safe?
    @html_safe
  end
end
