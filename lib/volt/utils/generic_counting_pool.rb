require 'volt/utils/generic_pool'

module Volt
  # A counting pool behaves like a normal GenericPool, except for
  # each time lookup is called, remove should be called when complete.
  # The item will be completely removed from the GenericCountingPool
  # only when it has been removed an equal number of times it has been
  # looked up.
  class GenericCountingPool < GenericPool
    # return a created item with a count
    def generate_new(*args)
      [0, create(*args)]
    end

    # Finds an item and tracks that it was checked out.  Use
    # #remove when the item is no longer needed.
    def find(*args, &block)
      item = __lookup(*args, &block)

      item[0] += 1

      item[1]
    end

    # Lookups an item
    def lookup(*args, &block)
      item = super(*args, &block)

      item[1]
    end

    def transform_item(item)
      [0, item]
    end

    def remove(*args)
      item    = __lookup(*args)
      item[0] -= 1

      if item[0] == 0
        # Last one using this item has removed it.
        super(*args)
      end
    end
  end
end
