module Volt
  module LoginAsHelper
    def login_as(user)
      unless user.is_a?(Volt::User)
        raise "login_as must be passed a user instance, you passed a #{user.class.to_s}"
      end

      # Assign the user_id cookie to the signature for the user id
      cookies._user_id = Volt.user_login_signature(user)
    end
  end
end