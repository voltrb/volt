class Symbol
  def camelize
    to_s.camelize.to_sym
  end
  
  def underscore
    to_s.underscore.to_sym
  end
  
  def pluralize
    to_s.pluralize.to_sym
  end
  
  def singularize
    to_s.singularize.to_sym
  end
end