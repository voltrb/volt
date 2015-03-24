require 'thread'

module Volt
  class << self
    # Get the user_id from the cookie
    def user_id
      # Check for a user_id from with_user
      if (user_id = Thread.current['with_user_id'])
        return user_id
      end

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

    # as_user lets you run a block as another user
    #
    # @param user_id [Integer]
    def as_user(user_id)
      previous_id = Thread.current['with_user_id']
      Thread.current['with_user_id'] = user_id

      yield

      Thread.current['with_user_id'] = previous_id
    end

    # True if the user is logged in and the user is loaded
    def current_user?
      !current_user.nil?
    end

    # Return the current user.
    def current_user
      user_id = self.user_id
      $page.store._users.find_one(_id: user_id) if user_id
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
