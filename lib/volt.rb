require 'volt/volt/environment'
require 'volt/extra_core/extra_core'
require 'volt/reactive/computation'
require 'volt/reactive/dependency'
require 'volt/config'
if RUBY_PLATFORM == 'opal'
else
  require 'volt/data_stores/data_store'
end
require 'volt/volt/users'

module Volt
  @in_browser = if RUBY_PLATFORM == 'opal'
                  `!!document && !window.OPAL_SPEC_PHANTOM`
                else
                  false
                end

  class << self
    def root
      @root ||= File.expand_path(Dir.pwd)
    end

    attr_writer :root

    def server?
      !!ENV['SERVER']
    end

    def client?
      !ENV['SERVER']
    end

    def source_maps?
      !!ENV['MAPS']
    end

    def env
      @env ||= Volt::Environment.new
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    attr_writer :logger

    def in_browser?
      @in_browser
    end

    # Get the user_id from the cookie
    def user_id
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

      if user_id_signature.nil?
        return nil
      else
        index = user_id_signature.index(':')
        user_id = user_id_signature[0...index]

        if RUBY_PLATFORM != 'opal'
          hash = user_id_signature[(index+1)..-1]

          # Make sure the user hash matches
          if BCrypt::Password.new(hash) != "#{Volt.config.app_secret}::#{user._id}"
            # user id has been tampered with, reject
            raise "user id or hash has been tampered with"
          end

        end

        return user_id
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
        return $page.store._users.find_one(_id: user_id)
      else
        return nil
      end
    end

  end
end

