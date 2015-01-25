unless RUBY_PLATFORM == 'opal'
  require 'bcrypt'
end

module Volt
  class User < Model
    # returns login field name depending on config settings
    def self.login_field
      if Volt.config.try(:public).try(:auth).try(:use_username)
        :username
      else
        :email
      end
    end

    validate login_field, unique: true, length: 8
    validate :email, email: true

    if RUBY_PLATFORM == 'opal'
      # Don't validate on the server
      validate :password, length: 8
    end

    def password=(val)
      if Volt.server?
        # on the server, we bcrypt the password and store the result
        self._hashed_password = BCrypt::Password.create(val)
      else
        # Assign the attribute
        self._password = val
      end
    end
  end
end
