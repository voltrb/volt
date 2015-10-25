if RUBY_PLATFORM == 'opal'
  require 'time'

  class Time
    # Patchs a bug in the Time class, where two instances of time with the same
    # value do not hash to the same hash as they do in MRI.
    # https://github.com/opal/opal/issues/963
    def hash
      "Time:#{to_i}"
    end
   
    # Patches backported Opal Time because it's missing
    # this method 
    def getlocal  
      s = self.to_f - self.utc_offset
      ::Time.at(self.to_f)
    end
  end
end
