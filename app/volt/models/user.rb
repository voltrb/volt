if RUBY_PLATFORM != 'opal'
  require 'bcrypt'
end

class User < Volt::Model
  # returns true if the user configured using the username
  def self.use_username?
    auth = Volt.config.auth
    auth && auth.use_username
  end

  if use_username?
    # use username
    validate :username, unique: true, length: 8
  else
    # use e-mail
    # TODO: Needs to validate email format
    validate :email, unique: true, length: 8
  end
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
