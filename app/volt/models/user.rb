require 'bcrypt' if RUBY_PLATFORM != 'opal'

module Volt
  class User < Model
    # returns true if the user configured using the username
    def self.login_field
      if Volt.config.public.try(:auth).try(:use_username)
        :username
      else
        :email
      end
    end

    validate login_field, unique: true, length: 8

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
end
