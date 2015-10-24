# Local calculations for use on the client only

class VoltTime
  
  def change_local(options)
    t = @time.getlocal
    new_year = options.fetch(:year, t.year)
    new_month = options.fetch(:month, t.month)
    new_day   = options.fetch(:day, t.day)
    new_hour  = options.fetch(:hour, t.hour)
    new_min   = options.fetch(:min, options[:hour] ? 0 : t.min)
    new_sec   = options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : t.sec)
    
    t = Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec)
    VoltTime.from_time(t)
  end
  
  # Returns a new VoltTime representing the beginning of the local day, 00:00:00
  def local_beginning_of_day
    change_local(hour: 0, min: 0, min: 0)
  end

  # Returns a new VoltTime representing the end of the local day, 23:59:59.999
  def local_end_of_day
    t = @time.getlocal
    t = Time.new(t.year, t.month, t.day, 23, 59, 59.999)
    VoltTime.from_time(t)
  end

  # Returns a new VoltTime representing the middle of the local day, 12:00:00
  def local_middle_of_day
    change_local(hour: 12)
  end

  # Returns the number of seconds since 00:00:00 of the current local day
  def local_seconds_since_midnight
    to_f - change_local(hour: 0).to_f
  end

  # Returns the number of seconds until 23:59:59.999 of current local day  
  def local_seconds_until_end_of_day
    local_end_of_day.to_f - to_f
  end

  # Returns a Range for the start to end of day
  def local_all_day
    local_beginning_of_day..local_end_of_day
  end
end
