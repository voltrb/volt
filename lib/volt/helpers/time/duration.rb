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
    
    # Adds durations or seconds to the duration
    def +(other)
      if other.is_a?(Volt::Duration)
        Volt::Duration.new(value + other.value, parts + other.parts)
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
    
    private
    
      def sum(sign, time = VoltTime.now)
        parts.inject(time) do |t, (type, number)|
          t.advance({type => number*sign})
        end
      end

      # Ensures that the Duration responds like the value to other methods
      def method_missing(method, *args, &block)
        value.send(method, *args, &block)
      end
     
  end
end
