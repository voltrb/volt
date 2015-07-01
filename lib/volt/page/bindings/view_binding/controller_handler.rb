module Volt
  class ControllerHandler
    attr_reader :controller, :action

    # Checks to see if a controller has a handler, and if not creates one.
    def self.fetch(controller, action)
      inst = controller.instance_variable_get('@__handler')

      unless inst
        inst = new(controller, action)
        controller.instance_variable_set('@__handler', inst)
      end

      inst
    end

    def initialize(controller, action)
      @controller = controller
      @action = action.to_sym if action

      @called_methods = {}
    end

    def call_action(stage_prefix = nil, stage_suffix = nil)
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

      # Don't call if its already been called
      return if @called_methods[method_name]

      # Track that this method got called
      @called_methods[method_name] = true

      # If no stage, then we are calling the main action method,
      # so we should call the before/after actions
      unless has_stage
        if @controller.run_callbacks(:before_action, @action)
          # stop_chain was called
          return true
        end
      end

      @controller.send(method_name) if @controller.respond_to?(method_name)

      @controller.run_callbacks(:after_action, @action) unless has_stage

      # before_action chain was not stopped
      false
    end

    # Fetch the controller class
    def self.get_controller_and_action(controller_path)
      fail "Invalid controller path: #{controller_path.inspect}" unless controller_path && controller_path.size > 0

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
