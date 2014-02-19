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

  def plural?
    to_s.plural?
  end

  def singular?
    to_s.singular?
  end
end
