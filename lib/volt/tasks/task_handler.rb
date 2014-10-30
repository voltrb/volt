module Volt
  class TaskHandler
    if RUBY_PLATFORM == 'opal'
      # On the front-end we setup a proxy class to the backend that returns
      # promises for all calls.
      def self.method_missing(name, *args, &block)
        $page.tasks.call(self.name, name, *args, &block)
      end
    else
      def initialize(channel = nil, dispatcher = nil)
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

      # On the backend, we proxy all class methods like we would
      # on the front-end.  This returns a promise, even if the
      # original code did not.
      def self.method_missing(name, *args, &block)
        # TODO: optimize: this could run the inside first to see if it
        # returns a promise, so we don't have to wrap it.
        return Promise.new.then do
          new(nil, nil).send(name, *args, &block)
        end.resolve(nil)
      end

      # Provide access to the store collection
      def store
        $page.store
      end
    end
  end
end
