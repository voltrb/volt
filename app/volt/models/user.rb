if RUBY_PLATFORM != 'opal'
  require 'bcrypt'
end

puts "LOAD MODEL"

class User < Volt::Model
  validate :username, unique: true, length: 8
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

  # Login the user, return a promise for success
  def self.login(username, password)
    puts "Login now"
    UserTasks.login(username, password).then do |result|
      puts "Got: #{result.inspect}"

      # Assign the user_id cookie for the user
      $page.cookies._user_id = result

      # Pass nil back
      nil
    end.fail do |err|
      $page.flash._errors << err
    end
  end

  def self.logout
    $page.cookies.delete(:user_id)
  end
end
