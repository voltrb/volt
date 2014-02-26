require 'volt/page/bindings/base_binding'
require 'volt/page/targets/attribute_target'

class AttributeBinding < BaseBinding
  def initialize(page, target, context, binding_name, attribute_name, getter)
    # puts "New Attribute Binding: #{binding_name}, #{attribute_name}, #{getter}"
    super(page, target, context, binding_name)

    @attribute_name = attribute_name
    @getter = getter

    setup
  end

  def setup

    # Find the source for the content binding
    @value = value_from_getter(@getter)

    # Run the initial update (render)
    update

    @update_listener = @value.on('changed') { update }

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
      # puts "NEW VAL: #{current_value} : #{@value.inspect}"
    else
      current_value = element.is(':checked')
    end

    @value.cur = current_value
  end

  def element
    Element.find('#' + binding_name)
  end

  def update
    value = @value.cur

    if @attribute_name == 'checked'
      update_checked
      return
    end

    if value.is_a?(NilMethodCall) || value.nil?
      value = ''
    end

    self.value = value
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

  def update_checked
    value = @value.cur

    if value.is_a?(NilMethodCall) || value.nil?
      value = false
    end

    element.prop('checked', value)

  end

  def remove
    # puts "REMOVE #{self.inspect}"
    # Unbind events, leave the element there since attribute bindings
    # aren't responsible for it being there.
    case @attribute_name
    when 'value'
      element.off('input.attrbind', nil)
    when 'checked'
      element.off('change.attrbind', nil)
    end

    # Value is a reactive template, remove it
    @value.remove if @value


    if @update_listener
      @update_listener.remove
      @update_listener = nil
    end

    # Clear any references
    @target = nil
    @context = nil
    @getter = nil
    @value = nil

    # puts self.instance_values.inspect
  end

  def remove_anchors
    raise "attribute bindings do not have anchors, can not remove them"
  end


end
