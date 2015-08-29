require 'volt/page/bindings/base_binding'
require 'volt/page/targets/attribute_target'

module Volt
  class AttributeBinding < BaseBinding
    def initialize(volt_app, target, context, binding_name, attribute_name, getter, setter)
      super(volt_app, target, context, binding_name)

      @attribute_name = attribute_name
      @getter         = getter
      @setter         = setter

      setup
    end

    def setup
      if `#{element}.is('select')`
        @is_select = true
      elsif `#{element}.is('[type=hidden]')`
        @is_hidden = true
      elsif `#{element}.is('[type=radio]')`
        @is_radio = true
        @selected_value = `#{element}.attr('value') || ''`
      elsif `#{element}.is('option')`
        @is_option = true
      end

      if @is_option
      else
        # Bind so when this value updates, we update
        case @attribute_name
          when 'value'
            changed_event = Proc.new { changed }
            if @is_select
              `#{element}.on('change.attrbind', #{changed_event})`

              invalidate_proc = Proc.new { invalidate }
              `#{element}.on('invalidate', #{invalidate_proc})`
            elsif @is_hidden
              `#{element}.watch('value', #{changed_event})`
            else
              `#{element}.on('input.attrbind', #{changed_event})`
            end
          when 'checked'
            changed_event = proc { |event| changed(event) }
            `#{element}.on('change.attrbind', #{changed_event})`
        end
      end

      # Listen for changes
      @computation = lambda do
        begin
          @context.instance_eval(&@getter)
        rescue => e
          getter_fail(e)
          ''
        end
      end.watch_and_resolve!(
        method(:update),
        method(:getter_fail)
      )

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

        @string_template_renderer_computation = lambda do
          self.value = @string_template_renderer.html
        end.watch!
      else
        new_value = '' if new_value.is_a?(NilMethodCall) || new_value.nil?

        self.value = new_value
      end
    end

    def value=(val)
      case @attribute_name
        when 'value'
          if @is_option
            # When a new option is added, we trigger the invalidate event on the
            # parent select so it will re-run update on the next tick and set
            # the correct option.
            `#{element}.parent('select').trigger('invalidate');`
          end
          # TODO: only update if its not the same, this keeps it from moving the
          # cursor in text fields.
          `#{element}.val(#{val})` if val != `(#{element}.val() || '')`
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

    # On select boxes, when an option is added/changed, we want to run update
    # again.  By calling invalidate, it will run at most once on the next tick.
    def invalidate
      @computation.invalidate!
    end

    def update_checked(value)
      value = false if value.is_a?(NilMethodCall) || value.nil?

      value = (@selected_value == value) if @is_radio

      `#{element}.prop('checked', #{value})`
    end

    def remove
      # Unbind events, leave the element there since attribute bindings
      # aren't responsible for it being there.
      case @attribute_name
        when 'value'
          if @is_select
            `#{element}.off('change.attrbind')`
            `#{element}.off('invalidate')`
          elsif @is_hidden
            `#{element}.unwatch('value')`
          else
            `#{element}.off('input.attrbind', #{nil})`
          end
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
