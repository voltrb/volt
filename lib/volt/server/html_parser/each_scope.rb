class EachScope < ViewScope
  def initialize(handler, path, content)
    super(handler, path)
    @content, @variable_name = content.strip.split(/ as /)
  end
  
  def close_scope
    puts "CLOSE EACH"
    binding_number = @handler.scope[-2].binding_number
    @handler.scope[-2].binding_number += 1
    @path += "/_template/#{binding_number}"
    
    super
    
    @handler.html << "<!-- $#{binding_number} --><!-- $/#{binding_number} -->"
		@handler.scope.last.save_binding(binding_number, "lambda { |__p, __t, __c, __id| EachBinding.new(__p, __t, __c, __id, Proc.new { #{@content} }, #{@variable_name.inspect}, #{@path.inspect}) }")
    
  end
end