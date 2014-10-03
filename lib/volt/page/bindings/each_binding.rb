require 'volt/page/bindings/base_binding'

class EachBinding < BaseBinding
  def initialize(page, target, context, binding_name, getter, variable_name, template_name)
    super(page, target, context, binding_name)

    @item_name = variable_name
    @template_name = template_name

    @templates = []

    @getter = getter

    # Listen for changes
    @computation = -> { reload }.watch!
  end

  # When a changed event happens, we update to the new size.
  def reload
    begin
      value = @context.instance_eval(&@getter)
    rescue => e
      Volt.logger.error("EachBinding Error: #{e.inspect}")
      value = []
    end

    # Since we're checking things like size, we don't want this to be re-triggered on a
    # size change, so we run without tracking.
    Computation.run_without_tracking do
      # puts "RELOAD:-------------- #{value.inspect}"
      # Adjust to the new size
      values = current_values(value)
      @value = values

      @added_listener.remove if @added_listener
      @removed_listener.remove if @removed_listener

      if @value.respond_to?(:on)
        @added_listener = @value.on('added') { |position| item_added(position) }
        @removed_listener = @value.on('removed') { |position| item_removed(position) }
      end

      templates_size = @templates.size
      values_size = values.size

      # Start over, re-create all nodes
      (templates_size-1).downto(0) do |index|
        item_removed(index)
      end
      0.upto(values_size-1) do |index|
        item_added(index)
      end
    end
  end

  def item_removed(position)
    # Remove dependency
    @templates[position].context.locals[:index_dependency].remove

    # puts "REMOVE AT: #{position.inspect} - #{@templates[position].inspect} - #{@templates.inspect}"
    @templates[position].remove_anchors
    @templates[position].remove
    @templates.delete_at(position)

    # Removed at the position, update context for every item after this position
    update_indexes_after(position)
  end

  def item_added(position)
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

    position_dependency = Dependency.new
    item_context.locals[:index_dependency] = position_dependency

    # Get and set index
    item_context.locals[:index=] = Proc.new do |val|
      position_dependency.changed!
      item_context.locals[:_index_value] = val
    end

    item_context.locals[:index] = Proc.new do
      position_dependency.depend
      item_context.locals[:_index_value]
    end

    item_template = TemplateRenderer.new(@page, @target, item_context, binding_name, @template_name)
    @templates.insert(position, item_template)

    update_indexes_after(position)
  end

  # When items are added or removed in the middle of the list, we need
  # to update each templates index value.
  def update_indexes_after(start_index)
    size = @templates.size
    if size > 0
      start_index.upto(size-1) do |index|
        @templates[index].context.locals[:index=].call(index)
      end
    end
  end

  def current_values(values)
    return [] if values.is_a?(Model) || values.is_a?(Exception)
    values = values.attributes if values.respond_to?(:attributes)

    return values
  end


  # When this each_binding is removed, cleanup.
  def remove
    @computation.stop
    @computation = nil

    # Clear value
    @value = nil

    @added_listener.remove
    @added_listener = nil

    @removed_listener.remove
    @removed_listener = nil

    if @templates
      template_count = @templates.size
      template_count.times do |index|
        item_removed(template_count - index - 1)
      end
      # @templates.compact.each(&:remove)
      @templates = nil
    end

    super
  end


end
