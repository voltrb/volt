class UserTasks < Volt::TaskHandler
  # Login a user, takes a username and password

  def login(username, password)
    puts "Login user: #{username}"
    store._users.find(username: username).then do |users|
      puts "Found: #{users.inspect}"
      user = users.first

      puts "Password: #{password} vs #{user._hashed_password}"
      match_pass = BCrypt::Password.new(user._hashed_password)
      if match_pass == password
        return "#{user._id}:...temphash..."
      else
        raise "Password did not match"
      end
    end
  end
end
