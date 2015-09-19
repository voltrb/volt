require 'thread'

module Volt
  class << self
    # Get the user_id from the cookie
    def current_user_id
      # Check for a user_id from with_user
      if (user_id = Thread.current['with_user_id'])
        return user_id
      end

      user_id_signature = self.user_id_signature

      if user_id_signature.nil?
        nil
      else
        index = user_id_signature.index(':')

        # If no index, the cookie is invalid
        return nil unless index

        user_id = user_id_signature[0...index]

        if RUBY_PLATFORM != 'opal'
          hash = user_id_signature[(index + 1)..-1]

          # Make sure the user hash matches
          # TODO: We could cache the digest generation for even faster comparisons
          if hash != Digest::SHA256.hexdigest("#{Volt.config.app_secret}::#{user_id}")
            # user id has been tampered with, reject
            fail VoltUserError, 'user id or hash is incorrectly signed.  It may have been tampered with, the app secret changed, or generated in a different app.'
          end

        end

        user_id
      end
    end

    # as_user lets you run a block as another user
    #
    # @param user_or_user_id [Integer|Volt::Model]
    def as_user(user_or_id)
      # if we have a user, get the id
      user_id = user_or_id.is_a?(Volt::Model) ? user_or_id.id : user_or_id

      previous_id = Thread.current['with_user_id']
      Thread.current['with_user_id'] = user_id

      yield

      Thread.current['with_user_id'] = previous_id
    end

    unless RUBY_PLATFORM == 'opal'
      # Takes a user and returns a signed string that can be used for the
      # user_id cookie to login a user.
      def user_login_signature(user)
        fail 'app_secret is not configured' unless Volt.config.app_secret

        # TODO: returning here should be possible, but causes some issues
        # Salt the user id with the app_secret so the end user can't
        # tamper with the cookie
        signature = Digest::SHA256.hexdigest(salty_user_id(user.id))

        # Return user_id:hash on user id
        "#{user.id}:#{signature}"
      end
    end

    def skip_permissions
      Volt.run_in_mode(:skip_permissions) do
        yield
      end
    end

    # True if the user is logged in and the user is loaded
    def current_user?
      current_user.then do |user|
        !!user
      end
    end

    # Return the current user.
    def current_user
      user_id = current_user_id
      if user_id
        Volt.current_app.store._users.where(id: user_id).first
      else
        Promise.new.resolve(nil)
      end
    end

    # Put in a deprecation placeholder
    def user
      Volt.logger.warn('Deprecation: Volt.user has been renamed to Volt.current_user (to be more clear about what it returns).  Volt.user will be deprecated in the future.')
      current_user
    end

    def fetch_current_user
      Volt.logger.warn("Deprecation Warning: fetch current user have been depricated, Volt.current_user returns a promise now.")
      current_user
    end

    # Login the user, return a promise for success
    def login(username, password)
      UserTasks.login(login: username, password: password).then do |result|
        # Assign the user_id cookie for the user
        Volt.current_app.cookies._user_id = result

        # Pass nil back
        nil
      end
    end

    def logout
      # Notify the backend so we can remove the user_id from the user's channel
      UserTasks.logout
      
      # Remove the cookie so user is no longer logged in
      Volt.current_app.cookies.delete(:user_id)
    end

    # Fetches the user_id+signature from the correct spot depending on client
    # or server, does not verify it.
    def user_id_signature
      if Volt.client?
        user_id_signature = Volt.current_app.cookies._user_id
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


    private
    unless RUBY_PLATFORM == 'opal'
      def salty_user_id(user_id)
        "#{Volt.config.app_secret}::#{user_id}"
      end
    end
  end
end
