class User < Volt::Model
  # validate :_email, unique: true, length: 200

  def password=(val)
    self._password = '--encoded: ' + val
  end
end
