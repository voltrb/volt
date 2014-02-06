# GenericPool is a base class you can inherit from to cache items
# based on a lookup.
#
# GenericPool assumes a #create method, that takes the path arguments
# and reutrns a new instance.
#
# TODO: make the lookup/create threadsafe
class GenericPool
  def initialize
    @pool = {}
  end
  
  def lookup(*args)
    return @pool[args] ||= create(*args)
  end
  
  def remove(*args)
    @pool.delete(args)
  end
end