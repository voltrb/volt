# Patchs a bug in the Time class, where two instances of time with the same
# value do not hash to the same hash as they do in MRI.
# https://github.com/opal/opal/issues/963
if RUBY_PLATFORM == 'opal'
  require 'time'

  class Time
    def hash
      "Time:#{to_i}"
    end
  end
end