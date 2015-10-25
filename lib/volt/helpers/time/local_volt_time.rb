class VoltTime

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
  
end
