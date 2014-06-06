require 'volt/page/bindings/base_binding'

class EachBinding < BaseBinding
  def initialize(page, target, context, binding_name, getter, variable_name, template_name)
    super(page, target, context, binding_name)

    @item_name = variable_name
    @template_name = template_name

    # Find the source for the content binding
    @value = value_from_getter(getter)

    @templates = []

    # Run the initial render
    # update
    reload

    @added_listener = @value.on('added') { |_, position, item| item_added(position) }
    @changed_listener = @value.on('changed') { reload }
    @removed_listener = @value.on('removed') { |_, position| item_removed(position) }
  end

  # When a changed event happens, we update to the new size.
  def reload
    # Adjust to the new size
    values = current_values
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

  def item_removed(position)
    position = position.cur
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

    index = ReactiveValue.new(position)
    value = @value[index]

    item_context = SubContext.new({@item_name => value, :index => index, :parent => @value}, @context)

    item_template = TemplateRenderer.new(@page, @target, item_context, binding_name, @template_name)
    @templates.insert(position, item_template)

    # update_indexes_after(position)
  end

  # When items are added or removed in the middle of the list, we need
  # to update each templates index value.
  def update_indexes_after(start_index)
    size = @templates.size
    if size > 0
      puts @templates.inspect
      start_index.upto(size-1) do |index|
        @templates[index].context.locals[:index].cur = index
      end
    end
  end

  def current_values
    values = @value.cur

    return [] if values.is_a?(Model) || values.is_a?(Exception)
    values = values.attributes unless values.is_a?(ReactiveArray)

    return values
  end


  # When this each_binding is removed, cleanup.
  def remove
    @added_listener.remove
    @added_listener = nil

    @changed_listener.remove
    @changed_listener = nil

    @removed_listener.remove
    @removed_listener = nil

    if @templates
      @templates.compact.each(&:remove)
      @templates = nil
    end

    super
  end


end
