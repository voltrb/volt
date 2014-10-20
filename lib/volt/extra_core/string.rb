require 'volt/extra_core/inflector'

class String
  # TODO: replace with better implementations
  # NOTE: strings are currently immutable in Opal, so no ! methods

  # Turns a string into the camel case version.  If it is already camel case, it should
  # return the same string.
  def camelize(first_letter = :upper)
    new_str = gsub(/_[a-z]/) { |a| a[1].upcase }
    new_str = new_str[0].capitalize + new_str[1..-1] if first_letter == :upper

    new_str
  end

  # Returns the underscore version of a string.  If it is already underscore, it should
  # return the same string.
  def underscore
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
  end

  def dasherize
    gsub('_', '-')
  end

  def pluralize
    Volt::Inflector.pluralize(self)
  end

  def singularize
    Volt::Inflector.singularize(self)
  end

  def titleize
    gsub('_', ' ').split(' ').map(&:capitalize).join(' ')
  end

  def plural?
    # TODO: Temp implementation
    pluralize == self
  end

  def singular?
    # TODO: Temp implementation
    singularize == self
  end
end
