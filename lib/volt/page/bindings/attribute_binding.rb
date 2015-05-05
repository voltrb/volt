require 'volt/page/bindings/base_binding'
require 'volt/page/targets/attribute_target'

module Volt
  class AttributeBinding < BaseBinding
    def initialize(page, target, context, binding_name, attribute_name, getter, setter)
      super(page, target, context, binding_name)

      @attribute_name = attribute_name
      @getter         = getter
      @setter         = setter

      setup
    end

    def setup
      # Listen for changes
      @computation = -> do
        begin
          @context.instance_eval(&@getter)
        rescue => e
          Volt.logger.error("AttributeBinding Error: #{e.inspect}")
          ''
        end
      end.watch_and_resolve! do |result|
        update(result)
      end

      @is_check = `#{element}.is('select')`
      @is_radio = `#{element}.is('[type=radio]')`
      if @is_radio
        @selected_value = `#{element}.attr('value') || ''`
      end

      # Bind so when this value updates, we update
      case @attribute_name
        when 'value'
          changed_event = Proc.new { changed }
          if @is_check
            `#{element}.on('change', #{changed_event})`
          end
          `#{element}.watch('value', #{changed_event})`
        when 'checked'
          changed_event = Proc.new { |event| changed(event) }
          `#{element}.on('change.attrbind', #{changed_event})`
      end
    end

    def changed(event = nil)
      case @attribute_name
        when 'value'
          current_value = `#{element}.val() || ''`
        else
          current_value = `#{element}.is(':checked')`
      end

      if @is_radio
        if current_value
          # if it is a radio button and its checked
          @context.instance_exec(@selected_value, &@setter)
        end
      else
        @context.instance_exec(current_value, &@setter)
      end
    end

    def element
      @element ||= `$('#' + #{binding_name})`
    end

    def update(new_value)
      if @attribute_name == 'checked'
        update_checked(new_value)
        return
      end

      # Stop any previous reactive template computations
      @string_template_renderer_computation.stop if @string_template_renderer_computation
      @string_template_renderer.remove if @string_template_renderer

      if new_value.is_a?(StringTemplateRenderer)
        # We don't need to refetch the whole reactive template to
        # update, we can just depend on it and update directly.
        @string_template_renderer = new_value

        @string_template_renderer_computation = -> do
          self.value = @string_template_renderer.html
        end.watch!
      else
        if new_value.is_a?(NilMethodCall) || new_value.nil?
          new_value = ''
        end

        self.value = new_value
      end
    end

    def value=(val)
      case @attribute_name
        when 'value'
          # TODO: only update if its not the same, this keeps it from moving the
          # cursor in text fields.
          if val != `(#{element}.val() || '')`
            `#{element}.val(#{val})`
          end
        when 'disabled'
          # Disabled is handled specially, you can either return a boolean:
          # (true being disabled, false not disabled), or you can optionally
          # include the "disabled" string. (or any string)
          if val != false && val.present?
            `#{element}.attr('disabled', 'disabled')`
          else
            `#{element}.removeAttr('disabled')`
          end
        else
          `#{element}.attr(#{@attribute_name}, #{val})`
      end
    end

    def update_checked(value)
      if value.is_a?(NilMethodCall) || value.nil?
        value = false
      end

      if @is_radio
        value = (@selected_value == value)
      end

      `#{element}.prop('checked', #{value})`
    end

    def remove
      # Unbind events, leave the element there since attribute bindings
      # aren't responsible for it being there.
      case @attribute_name
        when 'value'
          `#{element}.off('input.attrbind', #{nil})`
          `#{element}.off('change')`
          `#{element}.unwatch('value')`
        when 'checked'
          `#{element}.off('change.attrbind', #{nil})`
      end

      if @computation
        @computation.stop
        @computation = nil
      end

      @string_template_renderer.remove if @string_template_renderer
      @string_template_renderer_computation.stop if @string_template_renderer_computation

      # Clear any references
      @target  = nil
      @context = nil
      @getter  = nil
    end

    def remove_anchors
      fail 'attribute bindings do not have anchors, can not remove them'
    end
  end
end
