require 'volt/page/bindings/base_binding'

class EachBinding < BaseBinding
  def initialize(page, target, context, binding_name, getter, variable_name, template_name)
    # puts "New EACH Binding"

    super(page, target, context, binding_name)

    @item_name = variable_name
    @template_name = template_name

    # Find the source for the content binding
    @value = value_from_getter(getter)

    @templates = []

    # Run the initial render
    update

    @added_listener = @value.on('added') { |_, position, item| item_added(position) }
    @changed_listener = @value.on('changed') { reload }
    @removed_listener = @value.on('removed') { |_, position| item_removed(position) }
  end
  
  # When a change event comes through, its most likely upstream, so the whole
  # array might have changed.  In this case, just reload the whole thing
  # TODO: Track to make sure the changed event isn't being called too often (it is currently)
  def reload
    # ObjectTracker.enable_cache
    # Remove all of the current templates
    if @templates
      @templates.each do |template|
        template.remove_anchors
        
        # TODO: Make sure this is being removed since we already removed the anchors
        template.remove
      end
    end
    
    @templates = []
    
    # Run update again to rebuild
    update

    # ObjectTracker.disable_cache
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
    # puts "ADDED 1"
    binding_name = @@binding_number
    @@binding_number += 1

    if position >= @templates.size
      # Setup new bindings in the spot we want to insert the item
      section.insert_anchor_before_end(binding_name)
    else
      # Insert the item before an existing item 
      section.insert_anchor_before(binding_name, @templates[position].binding_name)
    end

    index = ReactiveValue.new(position)
    value = @value[index]
    
    item_context = SubContext.new({@item_name => value, :index => index, :parent => @value}, @context)

    item_template = TemplateRenderer.new(@page, @target, item_context, binding_name, @template_name)
    @templates.insert(position, item_template)
    
    update_indexes_after(position)
  end
  
  # When items are added or removed in the middle of the list, we need
  # to update each templates index value.
  def update_indexes_after(start_index)
    size = @templates.size
    if size > 0
      start_index.upto(@templates.size-1) do |index|
        @templates[index].context.locals[:index].cur = index
      end
    end
  end

  def update(item=nil)
    if item
      values = [item]
    else
      values = @value.cur
      return if values.is_a?(Model) || values.is_a?(Exception)
      values = values.attributes
    end

    # TODO: Switch to #each?
    values.each_with_index do |value,index|
      item_added(index)
    end
  end

  # When this each_binding is removed, cleanup.
  def remove
    # puts "Remove Each"
    @added_listener.remove
    @added_listener = nil
    
    @changed_listener.remove
    @changed_listener = nil
    
    @removed_listener.remove
    @removed_listener = nil

    @templates.each(&:remove)
    @templates = nil
    
    super
  end


end