# module Hash
#   class Indifferent < Hash
#     def []=(key, value)
#       super(convert_key(key), value)
#     end
#
#     def [](key)
#       super(convert_key(key))
#     end
#
#     def key?(key)
#       super(convert_key(key))
#     end
#
#     def fetch(key, *args)
#       super(convert_key(key), *args)
#     end
#
#     private
#
#     # Converts all keys to symbols for assignments
#     def convert_key(key)
#       key.is_a?(String) ? key : key.to_sym
#     end
#   end
# end
class Hash
  # Returns a hash that includes everything but the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false, c: nil}
  #
  # This is useful for limiting a set of parameters to everything but a few known toggles:
  #   @person.update(params[:person].except(:admin))
  def except(*keys)
    dup.except!(*keys)
  end

  # Replaces the hash without the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except!(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false }
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end
