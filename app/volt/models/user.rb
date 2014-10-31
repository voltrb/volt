class User < Volt::Model
  validate :username, unique: true, length: 8
  validate :password, length: 8

  def password=(val)
    if Volt.server?
      self._password = '--encoded: ' + val
    else
      self._password = val
    end
  end
end
