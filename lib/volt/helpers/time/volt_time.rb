# Volt needs its own date/time class because of the differences between
# how Opal (i.e. JavaScript) and Ruby handle timezones. In JavaScript
# there are only two possible timezones, the local zone and UTC, while
# in Ruby any timezone can be set.
# VoltTime is always stored in UTC but can be converted to the local timezone.
# Because of Opal issue , VoltTime could not be Volt::Time.
# Because of Opal issue , VoltTime could not be a subclass of ::Time

class VoltTime
  # Since VoltTime is required by the user, we don't add it to the FIELD_CASTS
  # list until after it is included, since we don't have access to the class
  # here.
  if defined?(Volt::FieldHelpers)
    Volt::FieldHelpers::FIELD_CASTS[VoltTime] = nil
  end

  # A VoltTime can be initialized from either local or UTC timezone.
  # If no parameters are provided then the current time is initialized.
  # Zone must be specified (as :local or :utc) if any parts of the date are given
  # to be clear whether VoltTime should assume that the parameters
  # are for a local or utc time.
  def initialize(zone = nil, year = nil, month = nil, day = nil, hour = nil, min = nil, sec = nil)

    # Case when all params are nil - create time now
    if !zone || !year
      @time = ::Time.new.getutc
    elsif zone == :utc
      t = ::Time.new(year, month, day, hour, min, sec)
      @time = (t + t.utc_offset).getutc
    elsif zone == :local
      @time = ::Time.new(year, month, day, hour, min, sec).getutc
    else
      raise ArgumentError, "Specify zone as :utc or :local"
    end
  end

  class << self

    # Returns a VoltTime from a ::Time
    def from_time(time)
      VoltTime.new.set_time(time)
    end

    # Returns the time now in the UTC timezone
    def now
      VoltTime.new
    end

    # Live now acts just like now, except it invalidates any computations the
    # VoltTime object is used in at every interval.  This makes it easy to
    # display live timer's.
    def live_now(interval=1000)
      dep = Volt::Dependency.new
      dep.depend
      Volt::Timers.client_set_timeout(interval) do
        dep.changed!
      end
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
      @time == other.try(:getutc)
    end
  end

  def to_s
    @time.to_s
  end

  def inspect
    @time.inspect
  end

  def + (other)
    if other.is_a?(Volt::Duration)
      other.sum(1, self)
    else
      VoltTime.from_time(@time + other)
    end
  end

  def - (other)
    if other.is_a?(VoltTime)
      @time - other.getutc
    elsif other.is_a?(::Time)
      @time - other
    elsif other.is_a?(Volt::Duration)
      other.sum(-1, self)
    else
      VoltTime.from_time(@time - other)
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

  # Get the local offset from UTC
  def local_offset
    @time.getlocal.utc_offset
  end

  def respond_to?(method_name, include_private = false)
    @time.respond_to?(method_name, include_private)
  end

  unless RUBY_PLATFORM == 'opal'
    # Marshal support for drb and ForkingServer
    def _dump(level)
      @time.to_i.to_s
    end

    def self._load(args)
      at(args.to_i)
    end
  end

  private

  def method_missing(method, *args, &block)
    @time.send(method, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    @time.respond_to?(method_name, include_private)
  end

end
