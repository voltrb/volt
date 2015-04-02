module Volt
  # GenericPool is a base class you can inherit from to cache items
  # based on a lookup.
  #
  # GenericPool assumes either a block is passed to lookup, or a
  # #create method, that takes the path arguments and reutrns a new instance.
  #
  # GenericPool can handle as deep of paths as needed.  You can also lookup
  # all of the items at a sub-path with #lookup_all
  #
  # TODO: make the lookup/create threadsafe
  class GenericPool
    attr_reader :pool

    def initialize
      @pool = {}
    end

    def clear
      @pool = {}
    end

    def lookup(*args, &block)
      section = @pool

      # TODO: This is to work around opal issue #500
      if RUBY_PLATFORM == 'opal'
        args.pop if args.last.nil?
      end

      args.each_with_index do |arg, index|
        last = (args.size - 1) == index

        if last
          # return, creating if needed
          return(section[arg] ||= create_new_item(*args, &block))
        else
          next_section = section[arg]
          next_section ||= (section[arg] = {})
          section      = next_section
        end
      end
    end

    # Does the actual creating, if a block is not passed in, it calls
    # #create on the class.
    def create_new_item(*args)
      if block_given?
        new_item = yield(*args)
      else
        new_item = create(*args)
      end

      transform_item(new_item)
    end

    # Allow other pools to override how the created item gets stored.
    def transform_item(item)
      item
    end

    # Make sure we call the pool one from lookup_all and not
    # an overridden one.
    alias_method :__lookup, :lookup

    def lookup_all(*args)
      result = __lookup(*args) { nil }

      if result
        result.values
      else
        []
      end
    end

    def remove(*args)
      stack   = []
      section = @pool

      args.each_with_index do |arg, index|
        stack << section

        if args.size - 1 == index
          section.delete(arg)
        else
          section = section[arg]
        end
      end

      (stack.size - 1).downto(1) do |index|
        node   = stack[index]
        parent = stack[index - 1]

        if node.size == 0
          parent.delete(args[index - 1])
        end
      end
    end

    def print
      puts '--- Running Queries ---'

      @pool.each_pair do |table, query_hash|
        query_hash.each_key do |query|
          puts "#{table.inspect}: #{query.inspect}"
        end
      end

      puts '---------------------'
    end
  end
end
