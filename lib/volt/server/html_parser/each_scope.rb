module Volt
  class EachScope < ViewScope
    def initialize(handler, path, content, with_index)
      super(handler, path)

      if with_index
        @content, @variable_name = content.split(/.each_with_index\s+do\s+\|/)
        @variable_name, @index_name = @variable_name.gsub(/\|/, '').split(/\s*,\s*/)
      else
        @content, @variable_name = content.split(/.each\s+do\s+\|/)
        @variable_name = @variable_name.gsub(/\|/, '')
      end
    end

    def close_scope
      binding_number                    = @handler.scope[-2].binding_number
      @handler.scope[-2].binding_number += 1
      @path                             += "/__template/#{binding_number}"

      super

      @handler.html << "<!-- $#{binding_number} --><!-- $/#{binding_number} -->"
      @handler.scope.last.save_binding(binding_number, "lambda { |__p, __t, __c, __id| Volt::EachBinding.new(__p, __t, __c, __id, Proc.new { #{@content} }, #{@variable_name.inspect}, #{@index_name.inspect}, #{@path.inspect}) }")
    end
  end
end
