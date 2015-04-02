class UserTasks < Volt::TaskHandler
  # Login a user, takes a login and password.  Login can be either a username
  # or an e-mail based on Volt.config.public.auth.use_username
  def login(login, password)
    query = { User.login_field => login }

    # During login we need access to the user's info even though we aren't the user
    Volt.skip_permissions do
      store._users.find(query).fetch_first do |user|
        fail 'User could not be found' unless user

        match_pass = BCrypt::Password.new(user._hashed_password)
        fail 'Password did not match' unless  match_pass == password
        fail 'app_secret is not configured' unless Volt.config.app_secret

        # TODO: returning here should be possible, but causes some issues
        # Salt the user id with the app_secret so the end user can't
        # tamper with the cookie
        signature = Digest::SHA256.hexdigest(salty_user_id(user._id))

        # Return user_id:hash on user id
        next "#{user._id}:#{signature}"
      end
    end
  end

  private

  def salty_user_id(user_id)
    "#{Volt.config.app_secret}::#{user_id}"
  end
end
