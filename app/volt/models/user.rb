require 'bcrypt' unless RUBY_PLATFORM == 'opal'

module Volt
  class User < Model
    field :password

    # returns login field name depending on config settings
    def self.login_field
      if Volt.config.try(:public).try(:auth).try(:use_username)
        :username
      else
        :email
      end
    end

    permissions(:read) do
      # Never pass the hashed_password to the client
      deny :hashed_password

      # Deny all if this isn't the owner
      deny if !id == Volt.current_user_id && !new?
    end

    unless RUBY_PLATFORM == 'opal'
      permissions(:update) do
        deny unless id == Volt.current_user_id
      end
    end

    validations do
      # Only validate password when it has changed
      if changed?(:password)
        # Don't validate on the server
        validate :password, length: 8
      end
    end

    # On the server, we hash the password and remove it (so we just store the hash)
    unless RUBY_PLATFORM == 'opal'
      before_save :hash_password

      def hash_password
        password = get('password')

        if password.present?
          # Clear the password
          set('password', nil)

          # Set the hashed_password field instead
          set('hashed_password', BCrypt::Password.create(password))
        end
      end
    end
  end
end
