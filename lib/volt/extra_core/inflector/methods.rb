# encoding: utf-8

# The Inflector transforms words from singular to plural, class names to table
# names, modularized class names to ones without, and class names to foreign
# keys. The default inflections for pluralization, singularization, and
# uncountable words are kept in inflections.rb.
module Volt
  module Inflector
    # Returns the plural form of the word in the string.
    #
    # If passed an optional +locale+ parameter, the word will be
    # pluralized using rules defined for that language. By default,
    # this parameter is set to <tt>:en</tt>.
    #
    #   'post'.pluralize             # => "posts"
    #   'octopus'.pluralize          # => "octopi"
    #   'sheep'.pluralize            # => "sheep"
    #   'words'.pluralize            # => "words"
    #   'CamelOctopus'.pluralize     # => "CamelOctopi"
    #   'ley'.pluralize(:es)         # => "leyes"
    def self.pluralize(word, locale = :en)
      apply_inflections(word, inflections(locale).plurals)
    end

    # The reverse of +pluralize+, returns the singular form of a word in a
    # string.
    #
    # If passed an optional +locale+ parameter, the word will be
    # pluralized using rules defined for that language. By default,
    # this parameter is set to <tt>:en</tt>.
    #
    #   'posts'.singularize            # => "post"
    #   'octopi'.singularize           # => "octopus"
    #   'sheep'.singularize            # => "sheep"
    #   'word'.singularize             # => "word"
    #   'CamelOctopi'.singularize      # => "CamelOctopus"
    #   'leyes'.singularize(:es)       # => "ley"
    def self.singularize(word, locale = :en)
      apply_inflections(word, inflections(locale).singulars)
    end

    private

    # Applies inflection rules for +singularize+ and +pluralize+.
    #
    #  apply_inflections('post', inflections.plurals)    # => "posts"
    #  apply_inflections('posts', inflections.singulars) # => "post"
    def self.apply_inflections(word, rules)
      result = word.to_s.dup

      if word.empty? || inflections.uncountables.include?(result.downcase[/\b\w+\Z/])
        result
      else
        rules.each do |(rule, replacement)|
          if result.match(rule)
            result = result.sub(rule, replacement)
            break
          end
        end
        result
      end
    end
  end
end
