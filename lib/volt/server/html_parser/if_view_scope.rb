class IfViewScope < ViewScope
  def initialize(handler, path, content)
    super(handler, path)

    @original_path = @path

    @last_content = content
    @branches = []

    # We haven't added the if yet
    @if_binding_number = @handler.last.binding_number
    @handler.last.binding_number += 1

    @path_number = 0

    new_path
  end

  def new_path
    @path = @original_path + "/__if#{@path_number}"
    @path_number += 1
  end

  # When we reach an else block, we basically commit the current html
  # and template, and start a new one.
  def add_else(content)
    close_scope(false)

    @last_content = content

    # Clear existing
    @html = ''
    @bindings = {}

    # Close scope removes us, so lets add it back.
    @handler.scope << self

    @binding_number = 0

    # Generate a new template path for this section.
    new_path
  end

  def close_scope(final=true)
    @branches << [@last_content, path]

    super()

    if final
      # Add the binding to the parent
      branches = @branches.map do |branch|
        content = branch[0]
        if content == nil
          content = nil.inspect
        else
          content = "Proc.new { #{branch[0]} }"
        end

        "[#{content}, #{branch[1].inspect}]"
      end.join(', ')

      new_scope = @handler.last

      # variables are captured for branches, so we must prefix them so they don't conflict.
      # page, target, context, id
      new_scope.save_binding(@if_binding_number, "lambda { |__p, __t, __c, __id| IfBinding.new(__p, __t, __c, __id, [#{branches}]) }")

      new_scope.html << "<!-- $#{@if_binding_number} --><!-- $/#{@if_binding_number} -->"
    end
  end
end
