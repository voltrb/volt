require_relative 'generic_pool'


class GenericCountingPool < GenericPool
  # return a created item with a count
  def generate_new(*args)
    [0, create(*args)]
  end
  
  def lookup(*args)
    item = super(*args)
    
    item[0] += 1
    
    return item[1]
  end
  
  def remove(*args)
    item = __lookup(*args)
    item[0] -= 1
    
    if item[0] == 0
      # Last one using this item has removed it.
      super(*args)
    end
  end
end
