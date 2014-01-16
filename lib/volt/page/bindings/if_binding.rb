require 'volt/page/bindings/base_binding'

class IfBinding < BaseBinding
  def initialize(target, context, binding_name, branches)
    getter, template_name = branches[0]
    # puts "New If Binding: #{binding_name}, #{getter.inspect}"


    super(target, context, binding_name)

    @branches = []
    @listeners = []
    
    branches.each do |branch|
      getter, template_name = branch
      
      if getter.present?
        # Lookup the value
        value = value_from_getter(getter)

        if value.reactive?
          # Trigger change when value changes
          @listeners << value.on('changed') { update }
        end
      else
        # A nil value means this is an unconditional else branch, it
        # should always be true
        value = true
      end
      
      @branches << [value, template_name]
    end
    
    update
  end
  
  def update
    # Find the true branch
    true_template = nil
    @branches.each do |branch|
      value, template_name = branch
      
      # TODO: A bug in opal requires us to check == true
      if value.cur.true? == true
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
        @template = TemplateRenderer.new(@target, @context, binding_name, true_template)
      end
    end
  end
  
  def remove
    # Remove all listeners on any reactive values
    @listeners.each(&:remove)

    @template.remove if @template
    
    super
  end
end