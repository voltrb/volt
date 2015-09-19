class UserTasks < Volt::Task
  # Login a user, takes a login and password.  Login can be either a username
  # or an e-mail based on Volt.config.public.auth.use_username
  #
  # login_info is a key with login and password (login may be e-mail)
  def login(login_info)
    login = login_info['login']
    password = login_info['password']

    query = { User.login_field => login }

    # During login we need access to the user's info even though we aren't the user
    Volt.skip_permissions do
      store._users.where(query).first.then do |user|
        fail VoltUserError, 'User could not be found' unless user

        match_pass = BCrypt::Password.new(user._hashed_password)
        fail 'Password did not match' unless  match_pass == password

        next Volt.user_login_signature(user)
      end
    end
  end

  def logout
    # Remove user_id from user's channel
    @channel.update_user_id(nil) if @channel
  end

end
