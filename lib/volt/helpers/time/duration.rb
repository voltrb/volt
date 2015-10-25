# Much of this class was borrowed from ActiveSupport:
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/duration.rb

module Volt
  class Duration
    attr_accessor :value, :parts
    
    def initialize(value, parts) 
      @value, @parts = value, parts
    end
    
    # Compares with the value on another Duration if Duration is passed
    # or just compares value with the other object
    def ==(other)
      if other.is_a?(Volt::Duration)
        other.value == value
      else
        other == value
      end
    end
    
    # Adds durations or duration to a VoltTime or seconds to the duration
    def +(other)
      if other.is_a?(Volt::Duration)
        Volt::Duration.new(value + other.value, parts + other.parts)
      elsif other.is_a?(VoltTime)
        sum(1, other)
      else
        Volt::Duration.new(value + other, parts + [[:seconds, other]])
      end
    end
    
    # Calculates a new Time which is the Duration in the future.
    # The default is since the current time
    def since(time = VoltTime.now)
      sum(1, time)
    end
    alias :from_now :since
    
    # Calculates a new Time which is the Duration in the past
    # The default is since the current time
    def ago(time = VoltTime.now)
      sum(-1, time)
    end
    alias :until :ago
    
    # Ensure that the Duration responds like the value to other methods
    def respond_to_missing?(method, include_private=false)
      @value.respond_to?(method, include_private)
    end

    def inspect
      to_sentence parts.
        reduce(::Hash.new(0)) { |h,(l,r)| h[l] += r; h }.
        sort_by {|unit,  _ | [:years, :months, :days, :minutes, :seconds].index(unit)}.
        map     {|unit, val| "#{val} #{val == 1 ? unit.to_s.chop : unit.to_s}"}
    end
    
    def sum(sign, time = VoltTime.now)
      parts.inject(time) do |t, (type, number)|
        t.advance({type => number*sign})
      end
    end

    private
    

      def to_sentence(array) 
        case array.length
          when 0
            ""
          when 1
            array[0]
          when 2
            "#{array[0]} and #{array[1]}"
          else
            "#{array[0...-1].join(', ')} and #{array[-1]}"
        end
      end

      # Ensures that the Duration responds like the value to other methods
      def method_missing(method, *args, &block)
        value.send(method, *args, &block)
      end
     
  end
end
