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
      # on the front-end.  This returns promises.
      def self.method_missing(name, *args, &block)
        promise = Promise.new

        begin
          result = new(nil, nil).send(name, *args, &block)

          promise.resolve(result)
        rescue => e
          puts "Task Error: #{e.inspect}"
          puts e.backtrace
          promise.reject(e)
        end

        promise
      end

      # Provide access to the store collection
      def store
        $page.store
      end
    end
  end
end
