# Some template bindings share the controller with other template bindings based
# on a name.  This class creates a cache based on the group_controller name and the
# controller class.
module Volt
  class GroupedControllers
    def initialize(name)
      @name = name
      @@pool ||= GenericCountingPool.new
    end

    def lookup_or_create(controller, &block)
      @@pool.find(@name, controller, &block)
    end

    def remove(controller)
      @@pool.remove(@name, controller)
    end

    def clear
      @@pool.clear
    end

    def inspect
      "<GroupedController @name:#{@name.inspect} #{@@pool.inspect}>"
    end
  end
end
