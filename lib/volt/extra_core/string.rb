require 'volt/extra_core/inflector'

class String
  # TODO: replace with better implementations
  # NOTE: strings are currently immutable in Opal, so no ! methods

  # Turns a string into the camel case version.  If it is already camel case, it should
  # return the same string.
  def camelize(first_letter = :upper)
    new_str = self.gsub(/_[a-z]/) { |a| a[1].upcase }
    new_str = new_str[0].capitalize + new_str[1..-1] if first_letter == :upper

    return new_str
  end

  # Returns the underscore version of a string.  If it is already underscore, it should
  # return the same string.
  def underscore
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
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
