# Volt needs its own date/time class because of the differences between 
# how Opal (i.e. JavaScript) and Ruby handle timezones. In JavaScript
# there are only two possible timezones, the local zone and UTC, while
# in Ruby any timezone can be set. 
# VoltTime is always stored in UTC but can be converted to the local timezone.
# It has most of the instance methods of ::Time apart from those that are
# ambiguous from a timezone point of view (e.g. #to_time))

module Volt
  class VoltTime

   # A VoltTime can be initialized from either local or UTC timezone. 
   # It can also be initialise to any timezone on Ruby, but on Opal only
   # to UTC or local.
   # If hour, minute or second is specified then the timezone must be specified
   # If only year, month, or day is specified then UTC is assumed
   def initialize(year = nil, month = nil, day = nil, hour = nil, min = nil, sec = nil, zone = nil)
    raise ArgumentError, "if you want to set the time components of Volt::VoltTime, specify :local or :utc" if year && (hour || min || sec) && !zone
    if !year
      @time = ::Time.new.getutc
    elsif !zone || zone == :utc
      t = ::Time.new(year, month, day, hour, min, sec)
      @time = (t + t.utc_offset).getutc
    elsif zone == :local
      @time = ::Time.new(year, month, day, hour, min, sec)
    else
      @time = ::Time.new(year, month, day, hour, min, sec, zone)
    end
   end
    
    class << self
      
      # Returns a VoltTime from by a ::Time
      def from_time(time)
        VoltTime.new.set_time(time)
      end
      
      # Returns the time now in the UTC timezone
      def now
        VoltTime.new
      end
      
      # Returns the time as seconds from the epoch Jan 1 1970
      def at(secs, usecs = 0)
        VoltTime.new.set_time(::Time.at(secs, usecs))
      end
      
      # Returns the name of the current local timezone
      def current_zone
        ::Time.new.zone
      end
      
      # Return the local timezone offset from UTC in hours
      # in seconds
      def current_offset
        ::Time.new.utc_offset
      end
    end

    # Sets Volt::Time from a ::Time object, converting to UTC if necessary
    def set_time(time)
      @time = time.getutc
      return self
    end
    
    def <=> (other)
      if other.is_a?(::Time)
        @time <=> other
      else
        @time <=> other.getutc
      end
    end
    
    def == (other)
      if other.is_a?(::Time)
        @time == other
      else
        @time == other.getutc
      end
    end

    def to_s
      @time.to_s
    end
    
    def inspect
      @time.inspect
    end
    
    # Returns a string representation of the local time
    def local_to_s
      @time.getlocal.to_s
    end
    
    # Returns a canonical representation of the local time
    def local_asctime
      @time.getlocal.asctime
    end
    
    # Returns a canonical representation of the local time
    def local_ctime
      @time.getlocal.ctime
    end
    
    # Formats the local time according to the provided string
    def local_strftime(string)
      @time.getlocal.strftime(string)
    end
    
    def + (other)
      Volt::VoltTime.from_time(@time + other)
    end
    
    def - (other)
      if other.is_a?(Volt::VoltTime)
        @time - other.getutc
      elsif other.is_a?(::Time)
        @time - other
      else 
        Volt::VoltTime.from_time(@time - other)
      end
    end
  
    # Redefining getlocal without a timezone parameter
    def getlocal
      @time.getlocal
    end
   
    # Redefining localtime without a timezone parameter
    def localtime
      # Opal 0.9.0 has no localtime method so use getlocal instead
      @time.getlocal
    end
    
    def respond_to?(method_name, include_private = false)
      !METHOD_BLACKLIST.include?(method_name.to_s) && @time.respond_to?(method_name, include_private)
    end
   
    private
    
      # The method blacklist excludes methods that 
      # are ambiguous from a timezone point of view
      METHOD_BLACKLIST = ["to_time", "to_date", "to_datetime"]
  
      def method_missing(method, *args, &block)
        if METHOD_BLACKLIST.include?(method.to_s)
          raise NoMethodError, "undefined method `#{method}' for #{self.inspect}:#{self.class}"
        else
          @time.send(method, *args, &block)
        end
      end
      
      def respond_to_missing?(method_name, include_private = false)
        if !METHOD_BLACKLIST.include?(method_name.to_s)
          @time.respond_to?(method_name, include_private)
        end
      end
      
  end
end