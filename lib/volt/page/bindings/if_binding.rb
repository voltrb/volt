require 'volt/page/bindings/base_binding'

class IfBinding < BaseBinding
  def initialize(page, target, context, binding_name, branches)
    super(page, target, context, binding_name)

    getter, template_name = branches[0]

    @branches = []
    @listeners = []

    branches.each do |branch|
      getter, template_name = branch

      if getter.present?
        puts "GOT GETTER: #{getter.inspect}"

        @computation = -> { update(getter.call) }.bind!
      else
        # A nil value means this is an unconditional else branch, it
        # should always be true
        value = true
      end

      @branches << [value, template_name]
    end

    update
  end

  def update(current_value)
    # Find the true branch
    true_template = nil
    @branches.each do |branch|
      value, template_name = branch

      current_value = value.cur

      # TODO: A bug in opal requires us to check == true
      if current_value.true? == true && !current_value.is_a?(Exception)
        # This branch is currently true
        true_template = template_name
        break
      end
    end

    # Change out the template only if the true branch has changed.
    if @last_true_template != true_template
      @last_true_template = true_template

      if @template
        @template.remove
        @template = nil
      end

      if true_template
        @template = TemplateRenderer.new(@page, @target, @context, binding_name, true_template)
      end
    end
  end

  def remove
    @template.remove if @template

    @computation.stop if @computation
    @computation = nil

    super
  end
end
