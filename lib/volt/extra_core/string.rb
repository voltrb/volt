require 'volt/extra_core/inflector'

class String
  # TODO: replace with better implementations
  # NOTE: strings are currently immutable in Opal, so no ! methods
  def camelize
    self.split("_").map {|s| s.capitalize }.join("")
  end

  def underscore
    self.scan(/[A-Z][a-z]*/).join("_").downcase
  end

  def dasherize
    self.gsub('_', '-')
  end

  def pluralize
    Inflector.pluralize(self)
  end

  def singularize
    Inflector.singularize(self)
  end

  def titleize
    self.gsub('_', ' ').split(' ').map {|w| w.capitalize }.join(' ')
  end

  def plural?
    # TODO: Temp implementation
    self.pluralize == self
  end

  def singular?
    # TODO: Temp implementation
    self.singularize == self
  end
end
