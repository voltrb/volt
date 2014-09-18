require 'volt/page/bindings/base_binding'

class ContentBinding < BaseBinding
  def initialize(page, target, context, binding_name, getter)
    puts "New Content Binding"
    super(page, target, context, binding_name)

    # Listen for changes
    @computation = -> { update(@context.instance_eval(&getter)) }.bind!
  end

  def update(value)
    puts "Update with: #{value}"
    # TODORW:
    value = value.nil? ? '' : value

    # Exception values display the exception as a string
    value = value.to_s

    # Update the html in this section
    # TODO: Move the formatter into another class.
    dom_section.html = value.gsub("\n", "<br />\n")
  end

  def remove
    @computation.stop if @computation
    @computation = nil

    super
  end


end
