require 'volt/page/bindings/base_binding'

class EachBinding < BaseBinding
  def initialize(page, target, context, binding_name, getter, variable_name, template_name)
    super(page, target, context, binding_name)

    @item_name = variable_name
    @template_name = template_name

    @templates = []

    @getter = getter

    # Listen for changes
    @computation = -> { reload(@context.instance_eval(&@getter)) }.watch!
  end

  # When a changed event happens, we update to the new size.
  def reload(value)

    # Since we're checking things like size, we don't want this to be re-triggered on a
    # size change, so we run without tracking.
    Computation.run_without_tracking do
      puts "RELOAD:--------------"
      # Adjust to the new size
      values = current_values(value)
      @value = values

      @added_listener.remove if @added_listener
      @removed_listener.remove if @removed_listener

      @added_listener = @value.on('added') { |position| item_added(position) }
      @removed_listener = @value.on('removed') { |position| item_removed(position) }

      templates_size = @templates.size
      values_size = values.size

      if templates_size < values_size
        (templates_size).upto(values_size-1) do |index|
          item_added(index)
        end
      elsif templates_size > values_size
        (templates_size-1).downto(values_size) do |index|
          item_removed(index)
        end
      end
    end
  end

  def item_removed(position)
    @templates[position].remove_anchors
    @templates[position].remove
    @templates.delete_at(position)

    # Removed at the position, update context for every item after this position
    update_indexes_after(position)
  end

  def item_added(position)
    # ObjectTracker.enable_cache
    binding_name = @@binding_number
    @@binding_number += 1

    if position >= @templates.size
      # Setup new bindings in the spot we want to insert the item
      dom_section.insert_anchor_before_end(binding_name)
    else
      # Insert the item before an existing item
      dom_section.insert_anchor_before(binding_name, @templates[position].binding_name)
    end

    # TODORW: :parent => @value may change
    item_context = SubContext.new({:_index_value => position, :parent => @value}, @context)
    item_context.locals[@item_name.to_sym] = Proc.new { @value[item_context.locals[:_index_value]] }
    item_context.locals[:index] = Proc.new { item_context.locals[:_index_value] }

    item_template = TemplateRenderer.new(@page, @target, item_context, binding_name, @template_name)
    @templates.insert(position, item_template)
  end

  # When items are added or removed in the middle of the list, we need
  # to update each templates index value.
  def update_indexes_after(start_index)
    size = @templates.size
    if size > 0
      start_index.upto(size-1) do |index|
        @templates[index].context.locals[:_index_value] = index
      end
    end
  end

  def current_values(values)
    return [] if values.is_a?(Model) || values.is_a?(Exception)
    values = values.attributes unless values.is_a?(ReactiveArray)

    return values
  end


  # When this each_binding is removed, cleanup.
  def remove
    @computation.stop

    # Clear value
    @value = nil

    @added_listener.remove
    @added_listener = nil
    #
    # @changed_listener.remove
    # @changed_listener = nil

    @removed_listener.remove
    @removed_listener = nil

    if @templates
      @templates.compact.each(&:remove)
      @templates = nil
    end

    super
  end


end
