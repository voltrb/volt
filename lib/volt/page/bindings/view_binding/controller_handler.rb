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

    # Fetch the controller class
    def self.get_controller_and_action(controller_path)
      raise "Invalid controller path: #{controller_path.inspect}" unless controller_path && controller_path.size > 0

      action = controller_path[-1]

      # Get the constant parts
      parts  = controller_path[0..-2].map { |v| v.tr('-', '_').camelize }

      # Do const lookups starting at object and working our way down.
      # So Volt::ProgressBar would lookup Volt, then ProgressBar on Volt.
      obj = Object
      parts.each do |part|
        if obj.const_defined?(part)
          obj = obj.const_get(part)
        else
          # return a blank ModelController
          return [ModelController, nil]
        end
      end

      [obj, action]
    end
  end
end