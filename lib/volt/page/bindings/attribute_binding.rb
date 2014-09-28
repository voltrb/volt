require 'volt/page/bindings/base_binding'
require 'volt/page/targets/attribute_target'

class AttributeBinding < BaseBinding
  def initialize(page, target, context, binding_name, attribute_name, getter, setter)
    super(page, target, context, binding_name)

    @attribute_name = attribute_name
    @getter = getter
    @setter = setter

    setup
  end

  def setup

    # Listen for changes
    @computation = -> do
      begin
        update(@context.instance_eval(&@getter))
      rescue => e
        puts "New Attribute Binding Error: #{self.inspect}"
        Volt.logger.error("AttributeBinding Error: #{e.inspect}")
        update('')
      end
    end.watch!

    # Bind so when this value updates, we update
    case @attribute_name
    when 'value'
      element.on('input.attrbind') { changed }
    when 'checked'
      element.on('change.attrbind') {|event| changed(event) }
    end
  end

  def changed(event=nil)
    case @attribute_name
    when 'value'
      current_value = element.value
    else
      current_value = element.is(':checked')
    end

    @context.instance_exec(current_value, &@setter)
  end

  def element
    Element.find('#' + binding_name)
  end

  def update(new_value)
    if @attribute_name == 'checked'
      update_checked(new_value)
      return
    end

    if new_value.is_a?(ReactiveTemplate)
      new_value = new_value.html
    end

    if new_value.is_a?(NilMethodCall) || new_value.nil?
      new_value = ''
    end

    self.value = new_value
  end

  def value=(val)
    case @attribute_name
    when 'value'
      # TODO: only update if its not the same, this keeps it from moving the
      # cursor in text fields.
      if val != element.value
        element.value = val
      end
    else
      element[@attribute_name] = val
    end
  end

  def update_checked(value)
    if value.is_a?(NilMethodCall) || value.nil?
      value = false
    end

    element.prop('checked', value)
  end

  def remove
    # Unbind events, leave the element there since attribute bindings
    # aren't responsible for it being there.
    case @attribute_name
    when 'value'
      element.off('input.attrbind', nil)
    when 'checked'
      element.off('change.attrbind', nil)
    end

    @computation.stop if @computation

    # Clear any references
    @target = nil
    @context = nil
    @getter = nil
  end

  def remove_anchors
    raise "attribute bindings do not have anchors, can not remove them"
  end


end
