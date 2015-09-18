# Much of this class was borrowed from ActiveSupport:
# https://github.com/rails/rails/blob/ca9736e78ca9348e785a5c78c8cc085c0c2d4731/activesupport/lib/active_support/core_ext/time/calculations.rb

class Time
  # Returns a new Time where one or more of the elements have been changed according
  # to the +options+ parameter. The time options (<tt>:hour</tt>, <tt>:min</tt>,
  # <tt>:sec</tt>, <tt>:usec</tt>) reset cascadingly, so if only the hour is passed,
  # then minute, sec, and usec is set to 0. If the hour and minute is passed, then
  # sec and usec is set to 0.  The +options+ parameter takes a hash with any of these
  # keys: <tt>:year</tt>, <tt>:month</tt>, <tt>:day</tt>, <tt>:hour</tt>, <tt>:min</tt>,
  # <tt>:sec</tt>, <tt>:usec</tt>.
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
    # new_usec  = options.fetch(:usec, (options[:hour] || options[:min] || options[:sec]) ? 0 : Rational(nsec, 1000))

    # TODO: Opal doesn't have rational yet, so usec's don't get added in right yet
    ::Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec, utc_offset)
  end

  def beginning_of_day
    #(self - seconds_since_midnight).change(usec: 0)
    change(hour: 0, min: 0, sec: 0)
  end

   # Returns a new Time representing the end of the day, 23:59:59.999999 (.999999999 in ruby1.9)
  def end_of_day
    change(
      hour: 23,
      min: 59,
      sec: 59,
      # usec: Rational(999999999, 1000)
    )
  end
end