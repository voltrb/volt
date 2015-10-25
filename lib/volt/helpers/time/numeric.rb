# Much of this class was borrowed from ActiveSupport:
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/numeric/time.rb
# and
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/integer/time.rb

require 'volt/helpers/time/duration'

class Numeric
  
  # Returns a duration for the number of seconds provided.
  def seconds
    Volt::Duration.new(self, [[:secs, self]])
  end
  alias :second :seconds
  
  # Returns a duration for the number of minutes provided.
  def minutes
    Volt::Duration.new(self * 60, [[:secs, self * 60]])
  end
  alias :minute :minutes
  
  # Returns a duration for the number of hours provided.
  def hours
    Volt::Duration.new(self * 60 * 60, [[:secs, self * 60 * 60]])
  end
  alias :hour :hours
  
  # Returns a duration for the number of days provided.
  def days
    Volt::Duration.new(self * 24.hours, [[:days, self]])
  end
  alias :day :days
  
  # Returns a duration for the number of weeks provided.
  def weeks
    Volt::Duration.new(self * 7.days, [[:days, self * 7]])
  end
  alias :week :weeks
  
  # Returns a duration for the number of fortnights provided.
  def fortnights
    Volt::Duration.new(self * 14.days, [[:days, self * 14]])
  end
  alias :fortnight :fortnights
  
  # Returns a duration for the number of months provided.
  # Ignores any fractional part of months
  def months
    Volt::Duration.new(self.to_i * 30.days, [[:months, self.to_i]])
  end
  alias :month :months
  
  # Returns a duration for the number of years provided
  # Ignores any fractional part of years
  def years
    Volt::Duration.new(self.to_i * 365.25.days, [[:years, self.to_i]])
  end
  alias :year :years
end
