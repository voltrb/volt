# GenericPool is a base class you can inherit from to cache items
# based on a lookup.
#
# GenericPool assumes a #create method, that takes the path arguments
# and reutrns a new instance.
#
# GenericPool can handle as deep of paths as needed.  You can also lookup
# all of the items at a sub-path with #lookup_all
#
# TODO: make the lookup/create threadsafe
class GenericPool
  def initialize
    @pool = {}
  end
  
  def lookup(*args)
    section = @pool
    
    args.each_with_index do |arg, index|
      last = (args.size-1) == index
      
      if last
        # return, creating if needed
        return section[arg] ||= create(*args)
      else
        next_section = section[arg]
        next_section ||= (section[arg] = {})
        section = next_section
      end
    end
  end
  
  # Make sure we call the pool one from lookup_all and not
  # an overridden one.
  alias_method :__lookup, :lookup
  
  def lookup_all(*args)
    __lookup(*args).values
  end
  
  def remove(*args)
    stack = []
    section = @pool
    
    args.each_with_index do |arg, index|      
      stack << section

      if args.size-1 == index
        section.delete(arg)
      else
        section = section[arg]
      end
    end
    
    (stack.size-1).downto(1) do |index|
      node = stack[index]
      parent = stack[index-1]
      
      if node.size == 0
        parent.delete(args[index-1])
      end
    end
  end
end