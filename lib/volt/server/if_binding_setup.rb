# With if bindings, we need to track each branch, which is on the
# same scope level as the original if statement.  We use this class
# to track each branch.

require 'volt/server/binding_setup'
class IfBindingSetup < BindingSetup
  def initialize
    @branches = []
  end

  def add_branch(content, template_name)
    @branches << [content, template_name]
  end

  def to_setup_code
    branches = @branches.map do |branch|
      content = branch[0]
      if content == nil
        content = nil.inspect
      else
        content = "Proc.new { #{branch[0]} }"
      end

      "[#{content}, #{branch[1].inspect}]"
    end.join(', ')

    # variables are captured for branches, so we must prefix them so they don't conflict.
    # page, target, context, id
    "lambda { |__p, __t, __c, __id| IfBinding.new(__p, __t, __c, __id, [#{branches}]) }"
  end
end
