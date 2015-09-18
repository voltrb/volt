require 'volt/controllers/collection_helpers'
require 'volt/controllers/login_as_helper'

module Volt
  class Task
    if RUBY_PLATFORM == 'opal'
      # On the front-end we setup a proxy class to the backend that returns
      # promises for all calls.
      def self.method_missing(name, *args, &block)
        # Meta data is passed from the browser to the server so the server can know
        # things like who's logged in.
        meta_data = {}

        user_id = Volt.current_app.cookies._user_id
        meta_data['user_id'] = user_id unless user_id.nil?

        Volt.current_app.tasks.call(self.name, name, meta_data, *args, &block)
      end
    else
      include CollectionHelpers
      include LoginAsHelper

      class_attribute :__timeout

      def initialize(volt_app, channel = nil, dispatcher = nil)
        @volt_app   = volt_app
        @channel    = channel
        @dispatcher = dispatcher
      end

      def self.inherited(subclass)
        @subclasses ||= []
        @subclasses << subclass
      end

      def self.known_handlers
        @subclasses ||= []
      end

      # Set the timeout for method calls on this task.  (The default is
      # Volt.config.worker_timeout)
      # Set 0 to disable timeout
      def self.timeout(value)
        self.__timeout = value
      end

      def cookies
        @cookies ||= Model.new
      end

      # Get the cookies that got set
      def fetch_cookies
        if @cookies
          @cookies.to_h.reject {|k,v| k == :id }
        end
      end

      # On the backend, we proxy all class methods like we would
      # on the front-end.  This returns a promise, even if the
      # original code did not.
      def self.method_missing(name, *args, &block)
        # TODO: optimize: this could run the inside first to see if it
        # returns a promise, so we don't have to wrap it.
        Promise.new.then do
          new(Volt.current_app, nil, nil).send(name, *args, &block)
        end.resolve(nil)
      end
    end
  end
end
