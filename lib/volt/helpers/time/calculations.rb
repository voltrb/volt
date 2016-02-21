# Much of this class was borrowed from ActiveSupport:
# https://github.com/rails/rails/blob/ca9736e78ca9348e785a5c78c8cc085c0c2d4731/activesupport/lib/active_support/core_ext/time/calculations.rb

class VoltTime

  COMMON_YEAR_DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  class << self
    # Returns the number of days in a month. If no year is provided assumes
    # the current year
    def days_in_month(month, year = now.year)
      if month == 2 && leap?(year)
        29
      else
        COMMON_YEAR_DAYS_IN_MONTH[month]
      end
    end

    # Returns true if the year is a leap year, otherwise false
    def leap?(year)
      if year%400 == 0 || (year%4 == 0 && year%100 != 0)
        true
      else
        false
      end
    end
  end

  # Returns a new Time where one or more of the elements have been changed according
  # to the +options+ parameter. The time options (<tt>:hour</tt>, <tt>:min</tt>,
  # <tt>:sec</tt>, <tt>:usec</tt>) reset cascadingly, so if only the hour is passed,
  # then minute, sec, and usec is set to 0. If the hour and minute is passed, then
  # sec and usec is set to 0.  The +options+ parameter takes a hash with any of these
  # keys: <tt>:year</tt>, <tt>:month</tt>, <tt>:day</tt>, <tt>:hour</tt>, <tt>:min</tt>,
  # <tt>:sec</tt>
  #
  #   Time.new(2012, 8, 29, 22, 35, 0).change(day: 1)              # => Time.new(2012, 8, 1, 22, 35, 0)
  #   Time.new(2012, 8, 29, 22, 35, 0).change(year: 1981, day: 1)  # => Time.new(1981, 8, 1, 22, 35, 0)
  #   Time.new(2012, 8, 29, 22, 35, 0).change(year: 1981, hour: 0) # => Time.new(1981, 8, 29, 0, 0, 0)
  def change(options)
    new_year  = options.fetch(:year, year)
    new_month = options.fetch(:month, month)
    new_day   = options.fetch(:day, day)
    new_hour  = options.fetch(:hour, hour)
    new_min   = options.fetch(:min, options[:hour] ? 0 : min)
    new_sec   = options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : sec)
    VoltTime.new(:utc, new_year, new_month, new_day, new_hour, new_min, new_sec)
  end

  # Returns a new time that has been advanced according to the +options+
  # parameter. The +options+ parameter is a hash with any of these keys:
  # <tt>:years</tt>, <tt>:months</tt>, <tt>:days</tt>, <tt>:hours</tt>, <tt>:mins</tt>,
  # <tt>:secs</tt>
  def advance(options)
    t = self
    t = advance_years(options[:years]) if options[:years]
    t = advance_months(options[:months]) if options[:months]
    t = advance_days(options[:days]) if options[:days]
    t = advance_hours(options[:hours]) if options[:hours]
    t = advance_minutes(options[:mins]) if options[:mins]
    t = advance_seconds(options[:secs]) if options[:secs]
    t
  end

  # Compares two VoltTime object to the given accuracy
  # The +accuracy+ parameter can be <tt>:year</tt>, <tt>:month</tt>
  # <tt>:day</tt>, <tt>:hour</tt>, <tt>:min</tt>, <tt>:sec</tt>
  # Returns 0 if the two dates are the same to the required accuracy
  # (e.g. the same year or the same day), 1 if the date called on is later
  # than the parameter, or -1 if the date called on is earlier than the parameter
  def compare(other, accuracy)
    case accuracy
    when :year then year <=> other.year
    when :month then compare_date_components(other, :month, :year)
    when :day then compare_date_components(other, :day, :month)
    when :hour, :min, :sec
      change(accuracy => send(accuracy)) <=> other.change(accuracy => other.send(accuracy))
    end
  end

  def compare?(other, accuracy)
    compare(other, accuracy) == 0 ? true : false
  end

  # Advances time by a number of years
  def advance_years(years)
    advance_to_date(to_date >> (years*12))
  end

  # Advances time by a number of months
  def advance_months(months)
    advance_to_date(to_date >> months)
  end

  # Advances time by a number of days
  def advance_days(days)
    advance_to_date(to_date + days)
  end

  # Advances time by a number of seconds
  def advance_seconds(secs)
    self + secs
  end

  # Advances time by a number of hours
  def advance_hours(hours)
    self + (hours * 60 * 60)
  end

  # Advances time by a number of minutes
  def advance_minutes(mins)
    self + (mins * 60)
  end

  # Converts the time to a date
  def to_date
    Date.new(year, month, day)
  end

  # Advances the time to the given date
  def advance_to_date(date)
    VoltTime.new(:utc, date.year, date.month, date.day, hour, min, sec + (usec/1.0e6))
  end

  # Adds a duration to the time
  def plus_with_duration(other)
    if other.is_a?(Volt::Duration)
    end
  end

  # Returns a new VoltTime representing the beginning of the day, 00:00:00
  def beginning_of_day
    change(hour: 0, min: 0, sec: 0)
  end

  # Returns a new VoltTime representing the end of the day, 23:59:59.999
  # Only milliseconds are supported in Opal
  def end_of_day
    VoltTime.new(:utc, year, month, day, 23, 59, 59.999)
  end

  # Returns a new Time for the middle of the day i.e. 12:00:00
  def middle_of_day
    change(hour: 12)
  end

  # Returns the number of seconds since 00:00:00 of the current day
  def seconds_since_midnight
    to_f - change(hour: 0).to_f
  end

  # Returns the number of seconds to the 23:59:59 of the current day
  def seconds_until_end_of_day
    end_of_day.to_f - to_f
  end

  # Returns a new VoltTime for the number of seconds ago
  def ago(seconds)
    since(-seconds)
  end

  # Returns a new VoltTime for the number of seconds since the current time
  def since(seconds)
    VoltTime.new.set_time(@time + seconds)
  end

  # Returns a new Time for the beginning of the current hour
  def beginning_of_hour
    change(min: 0)
  end

  # Returns a new Time for the end of the current hour
  # only milliseconds are supported in Opal
  def end_of_hour
    change(min: 59, sec: 59.999)
  end

  # Returns a new Time for beginning of the current minute
  def beginning_of_minute
    change(sec: 0)
  end

  # Returns a new Time for the end of the current minute
  def end_of_minute
    change(sec: 59.999)
  end

  # Returns a Range for the start to end of day
  def all_day
    beginning_of_day..end_of_day
  end

  private
    def compare_date_components(other, component, higher_component)
      if compare(other, higher_component) == 0
        send(component) <=> other.send(component)
      else
        compare(other, higher_component)
      end
    end

end
