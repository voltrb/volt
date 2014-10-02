# Some template bindings share the controller with other template bindings based
# on a name.  This class keeps track of the number of templates using this controller
# and clears it once no one else is using it.  Use #get or #inc to add to the count.
# #clear removes 1 from the count.  When the count is 0, delete the controller.
class GroupedControllers
  @@controllers = {}

  def initialize(name)
    @name = name
  end

  def get
    return (controller = self.controller) && controller[0]
  end

  def set(controller)
    @@controllers[@name] = [controller, 1]
  end

  def inc
    controller[1] += 1
  end

  def clear
    controller = self.controller
    controller[1] -= 1
    if controller[1] == 0
      @@controllers.delete(@name)
    end
  end

  private
    def controller
      @@controllers[@name]
    end
end