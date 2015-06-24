# Temp until https://github.com/opal/opal/pull/596
require 'set'

class Set
  def delete(o)
    if include?(o)
      @hash.delete(o)
      true
    end
  end

  def delete_if
    block_given? or return enum_for(__method__)
    # @hash.delete_if should be faster, but using it breaks the order
    # of enumeration in subclasses.
    select { |o| yield o }.each { |o| @hash.delete(o) }
    self
  end

  def to_a
    @hash.keys
  end
end
