class UserTasks < Volt::TaskHandler

  # Login a user, takes a login and password.  Login can be either a username
  # or an e-mail based on Volt.config.public.auth.use_username
  def login(login, password)
    query = { User.login_field => login }

    return store._users.find(query).then do |users|
      user = users.first

      if user
        match_pass = BCrypt::Password.new(user._hashed_password)
        if match_pass == password
          fail 'app_secret is not configured' unless Volt.config.app_secret

          # TODO: returning here should be possible, but causes some issues

          # Salt the user id with the app_secret so the end user can't
          # tamper with the cookie
          salty_password = "#{Volt.config.app_secret}::#{user._id}"
          signature = BCrypt::Password.create(salty_password)

          # Return user_id:hash on user id
          next "#{user._id}:#{signature}"
        else
          fail 'Password did not match'
        end
      else
        fail 'User could not be found'
      end
    end
  end
end
