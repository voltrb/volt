require 'volt/page/bindings/base_binding'

class ContentBinding < BaseBinding
  def initialize(target, context, binding_name, getter)
    # puts "new content binding: #{getter}"
    super(target, context, binding_name)

    # Find the source for the content binding
    @value = value_from_getter(getter)

    # Run the initial render
    update

    if @value.reactive?
      @changed_listener = @value.on('changed') { update }
    end
  end

  def update
    value = @value.cur.or('')
    
    # Exception values display the exception as a string
    value = value.to_s
    
    # Update the text in this section
    section.text = value
  end

  def remove
    if @changed_listener
      @changed_listener.remove
      @changed_listener = nil
    end

    super
  end


end