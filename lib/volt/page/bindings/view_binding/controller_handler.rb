module Volt
  class ControllerHandler
    attr_reader :controller, :action

    def initialize(controller, action)
      @controller = controller
      @action = action.to_sym if action
    end

    def call_action(stage_prefix=nil, stage_suffix=nil)
      return unless @action

      has_stage = stage_prefix || stage_suffix

      if has_stage
        method_name = @action
        method_name = "#{stage_prefix}_#{method_name}" if stage_prefix
        method_name = "#{method_name}_#{stage_suffix}" if stage_suffix

        method_name = method_name.to_sym
      else
        method_name = @action
      end

      # If no stage, then we are calling the main action method,
      # so we should call the before/after actions
      unless has_stage
        if @controller.run_actions(:before, @action)
          # stop_chain was called
          return true
        end
      end

      if @controller.respond_to?(method_name)
        @controller.send(method_name)
      end

      @controller.run_actions(:after, @action) unless has_stage

      # before_action chain was not stopped
      return false
    end
  end
end