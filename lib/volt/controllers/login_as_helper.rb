module Volt
  module LoginAsHelper
    def login_as(user)
      # Assign the user_id cookie to the signature for the user id
      cookies._user_id = Volt.user_login_signature(user)
    end
  end
end