require 'volt/page/bindings/base_binding'

class ContentBinding < BaseBinding
  def initialize(page, target, context, binding_name, getter)
    super(page, target, context, binding_name)

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

    # Update the html in this section
    # TODO: Move the formatter into another class.
    dom_section.html = value.gsub("\n", "<br />\n")
  end

  def remove
    if @changed_listener
      @changed_listener.remove
      @changed_listener = nil
    end

    super
  end


end
