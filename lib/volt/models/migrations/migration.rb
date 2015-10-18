# This is the base class for migrations.
require 'volt/reactive/eventable'

module Volt
  class Migration
    extend Eventable
    def self.inherited(klass)
      trigger!('inherited', klass)
    end

    def store
      Volt.current_app.store
    end

    def up
      raise "An up migration was not provided"
    end

    def down
      raise "A down migration was not provided"
    end
  end
end
