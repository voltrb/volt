if RUBY_PLATFORM != 'opal'
  require 'bcrypt'
end

class User < Volt::Model
  validate :username, unique: true, length: 8
  if RUBY_PLATFORM == 'opal'
    validate :password, length: 8
  end

  def password=(val)
    if Volt.server?
      puts "ENCODE: #{val.inspect}"
      self._hashed_password = BCrypt::Password.create(val)
    else
      self._password = val
    end
  end
end
