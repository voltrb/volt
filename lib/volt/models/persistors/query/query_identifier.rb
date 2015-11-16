# Volt allows you to pass blocks to .where queries.  The block will receive a
# single argument, which sumulates the row in the database.  On the row, you
# can call comparitors and use logical and/or (| and &) to build up queries.
#
# The QueryIdentifier class stores all methods called on it, and uses the
# QueryOp class to store logical operations.  You can call .to_query on the
# result to get an array representing the query.  This can then be normalized
# and called on the backend to answer the query.

module Volt
  class QueryIdentifier
    def initialize(from='ident')
      @from = from
    end

    def method_missing(method_name, *args)
      method_name = method_name.to_s
      # c for call

      args = escape(args)

      QueryIdentifier.new(['c', @from, method_name, *args])
    end

    def escape(args)
      args.map do |arg|
        if arg.is_a?(Array)
          # Escape the array
          arg.unshift('a')
        elsif arg.is_a?(Regexp)
          # Track regexp
          ['r', arg.to_s]
        else
          arg
        end
      end
    end

    def ==(val)
      method_missing(:==, val)
    end

    # def !
    #   method_missing(:!)
    # end

    # Special methods in ruby don't respond to method_missing, so setup methods
    # for them.
    # We need < and > until https://github.com/opal/opal/issues/1137 is fixed.
    ['=~', '!~', '&', '|', '<', '>', '<=', '>='].each do |op|
      define_method(op) do |val|
        __op(op, val)
      end
    end

    # And for unary ops
    def ~
      __op('~')
    end

    def +(val)
      method_missing(:+, val)
    end

    def __op(*args)
      QueryOp.new(['c', self, *escape(args)])
    end

    def coerce(other)
      unless other.is_a?(Volt::QueryIdentifier)
        other = Volt::QueryIdentifier.new(other)
      end

      [other, self]
    end

    def inspect
      "(#{@from.join(' ')})"
    end

    def to_s
      inspect
    end

    def to_query
      if @from.is_a?(Array)
        @from.map do |val|
          if val.is_a?(QueryIdentifier)
            val.to_query
          else
            val
          end
        end
      else
        @from
      end
    end
  end

  class QueryOp < QueryIdentifier

  end
end

# def where
#   ident = Volt::QueryIdentifier.new
#   yield(ident)
# end

# a = where {|v| ((v.name < 10) | (v.name > 5)) & ~(v.name == 'Ryan') }
# b = where {|v| 1 < v.name }
