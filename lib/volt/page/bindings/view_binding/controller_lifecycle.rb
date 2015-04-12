module Volt
  module ControllerLifecycle
    def self.call_action(controller, action, stage_method_name=nil)
      if stage_method_name
        method_name = stage_method_name
      else
        method_name = action
      end

      # If no stage, then we are calling the main action method,
      # so we should call the before/after actions
      unless stage_method_name
        action = action.to_sym
        if controller.run_actions(:before, action)
          # stop_chain was called
          return true
        end
      end

      if controller.respond_to?(method_name)
        controller.send(method_name)
      end

      controller.run_actions(:after, action) unless stage_method_name

      # before_action chain was not stopped
      return false
    end
  end
end