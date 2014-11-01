if RUBY_PLATFORM != 'opal'
  require 'bcrypt'
end

class User < Volt::Model
  validate :username, unique: true, length: 8
  if RUBY_PLATFORM == 'opal'
    # Don't validate on the server
    validate :password, length: 8
  end

  def password=(val)
    if Volt.server?
      # on the server, we bcrypt the password and store the result
      self._hashed_password = BCrypt::Password.create(val)
    else
      self._password = val
    end
  end
end
