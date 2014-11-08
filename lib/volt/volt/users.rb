module Volt

  # Login the user, return a promise for success
  def self.login(username, password)
    puts "Login now"
    UserTasks.login(username, password).then do |result|
      puts "Got: #{result.inspect}"

      # Assign the user_id cookie for the user
      $page.cookies._user_id = result

      # Pass nil back
      nil
    end
  end

  def self.logout
    $page.cookies.delete(:user_id)
  end
end