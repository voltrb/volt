# Some template bindings share the controller with other template bindings based
# on a name.  This class stores those and provides helper methods to clear/set/get.
class GroupedControllers
  @@controllers = {}

  def initialize(name)
    @name = name
  end

  def get
    @@controllers[@name]
  end

  def set(controller)
    @@controllers[@name] = controller
  end

  def clear
    @@controllers.delete(@name)
  end
end