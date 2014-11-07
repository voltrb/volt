class UserTasks < Volt::TaskHandler
  # Login a user, takes a username and password

  def login(username, password)
    puts "META: " + Thread.current['meta'].inspect

    if Volt.user
      puts "USER: " + Volt.user._name
    end

    return store._users.find(username: username).then do |users|
      user = users.first

      if user
        match_pass = BCrypt::Password.new(user._hashed_password)
        if match_pass == password
          raise "app_secret is not configured" unless Volt.config.app_secret

          # TODO: returning here should be possible, but causes some issues

          # Salt the user id with the app_secret so the end user can't tamper with the cookie
          signature = BCrypt::Password.create("#{Volt.config.app_secret}::#{user._id}")

          # Return user_id:hash on user id
          next "#{user._id}:#{signature}"
        else
          raise "Password did not match"
        end
      else
        raise "User could not be found"
      end
    end
  end
end
