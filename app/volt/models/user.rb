class User < Volt::Model
  def password=(val)
    self._password = '--encoded: ' + val
  end
end
