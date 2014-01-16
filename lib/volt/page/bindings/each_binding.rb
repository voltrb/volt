require 'volt/page/bindings/base_binding'

class EachBinding < BaseBinding
  def initialize(target, context, binding_name, getter, variable_name, template_name)
    # puts "New EACH Binding"

    super(target, context, binding_name)

    @item_name = variable_name
    @template_name = template_name

    # Find the source for the content binding
    @value = value_from_getter(getter)

    @templates = []

    # Run the initial render
    update

    @added_listener = @value.on('added') { |position, item| puts "ADDED" ; item_added(position) }
    @changed_listener = @value.on('changed') { puts "CHANGED" ; reload }
    @removed_listener = @value.on('removed') { |position| puts "REMOVED at #{position.inspect}" ; item_removed(position) }
  end
  
  # When a change event comes through, its most likely upstream, so the whole
  # array might have changed.  In this case, just reload the whole thing
  # TODO: Track to make sure the changed event isn't being called too often (it is currently)
  def reload
    # Remove all of the current templates
    if @templates
      @templates.each do |template|
        template.remove
        template.remove_anchors
      end
    end
    
    @templates = []
    
    # Run update again to rebuild
    update
  end

  def item_removed(position)
    position = position.cur
    @templates[position].remove
    @templates[position].remove_anchors
    @templates.delete_at(position)
    
    value_obj = @value.cur
    
    if value_obj
      size = value_obj.size - 1
    else
      size = 0
    end
    
    # puts "Position: #{position} to #{size}"
    
    # Removed at the position, update context for every item after this position
    position.upto(size) do |index|
      @templates[index].context.locals[:index].cur = index
    end
  end

  def item_added(position)
    # puts "ADDED AT #{position}"
    binding_name = @@binding_number
    @@binding_number += 1

    # Setup new bindings in the spot we want to insert the item
    section.insert_anchor_before_end(binding_name)

    index = ReactiveValue.new(position)
    value = @value[index]
    
    item_context = SubContext.new({@item_name => value, :index => index, :parent => @value}, @context)

    @templates << TemplateRenderer.new(@target, item_context, binding_name, @template_name)
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