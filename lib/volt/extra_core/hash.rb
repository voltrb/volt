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