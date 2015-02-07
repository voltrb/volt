module Volt
  class ComponentViewScope < ViewScope
    # The path passed in is the path used to lookup view's.  The path from the tag is passed in
    # as tag_name
    def initialize(handler, path, tag_name, attributes, unary)
      super(handler, path)

      @binding_in_path = path

      component_name = tag_name[1..-1].tr(':', '/')

      data_hash = []
      attributes.each_pair do |name, value|
        name = name.tr('-', '_')
        parts, binding_count = binding_parts_and_count(value)

        # if this attribute has bindings
        if binding_count > 0
          if binding_count > 1
            # Multiple bindings
          elsif parts.size == 1 && binding_count == 1
            # A single binding
            getter = value[2...-2].strip
            data_hash << "#{name.inspect} => Proc.new { #{getter} }"

            setter = getter_to_setter(getter)
            data_hash << "#{(name + '=').inspect} => Proc.new { |val| #{setter} }"

            # Add an _parent fetcher.  Useful for things like volt-fields to get the parent model.
            parent = parent_fetcher(getter)

            # TODO: This adds some overhead, perhaps there is a way to compute this dynamically on the
            # front-end.
            data_hash << "#{(name + '_parent').inspect} => Proc.new { #{parent} }"

            # Add a _last_method property.  This is useful
            data_hash << "#{(name + '_last_method').inspect} => #{last_method_name(getter).inspect}"
          end
        else
          # String
          data_hash << "#{name.inspect} => #{value.inspect}"
        end
      end

      @arguments = "#{component_name.inspect}, { #{data_hash.join(',')} }"
    end

    def close_scope
      binding_number                    = @handler.scope[-2].binding_number
      @handler.scope[-2].binding_number += 1
      @path                             += "/__template/#{binding_number}"

      super

      @handler.html << "<!-- $#{binding_number} --><!-- $/#{binding_number} -->"
      @handler.scope.last.save_binding(binding_number, "lambda { |__p, __t, __c, __id| Volt::ComponentBinding.new(__p, __t, __c, __id, #{@binding_in_path.inspect}, Proc.new { [#{@arguments}] }, #{@path.inspect}) }")
    end
  end
end