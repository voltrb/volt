module Volt
  class << self
    # Get the user_id from the cookie
    def user_id
      user_id_signature = self.user_id_signature

      if user_id_signature.nil?
        nil
      else
        index = user_id_signature.index(':')
        user_id = user_id_signature[0...index]

        if RUBY_PLATFORM != 'opal'
          hash = user_id_signature[(index + 1)..-1]

          # Make sure the user hash matches
          if BCrypt::Password.new(hash) != "#{Volt.config.app_secret}::#{user_id}"
            # user id has been tampered with, reject
            fail 'user id or hash has been tampered with'
          end

        end

        user_id
      end
    end

    # True if the user is logged in and the user is loaded
    def user?
      !!user
    end

    # Return the current user.
    def user
      user_id = self.user_id
      if user_id
        $page.store._users.find_one(_id: user_id)
      else
        nil
      end
    end

    # Login the user, return a promise for success
    def login(username, password)
      UserTasks.login(username, password).then do |result|
        # Assign the user_id cookie for the user
        $page.cookies._user_id = result

        # Pass nil back
        nil
      end
    end

    def logout
      $page.cookies.delete(:user_id)
    end

    # Fetches the user_id+signature from the correct spot depending on client
    # or server, does not verify it.
    def user_id_signature
      if Volt.client?
        user_id_signature = $page.cookies._user_id
      else
        # Check meta for the user id and validate it
        meta_data = Thread.current['meta']
        if meta_data
          user_id_signature = meta_data['user_id']
        else
          user_id_signature = nil
        end
      end

      user_id_signature
    end
  end
end
