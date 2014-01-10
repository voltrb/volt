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
    
    "lambda { |target, context, id| IfBinding.new(target, context, id, [#{branches}]) }"
  end
end