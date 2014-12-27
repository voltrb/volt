class Class
  # Provides a way to make class attributes that inherit.  Pass
  # in symbols for attribute names
  def class_attribute(*attrs)
    attrs.each do |name|
      define_singleton_method(name) { nil }

      ivar = "@#{name}"

      define_singleton_method("#{name}=") do |val|
        singleton_class.class_eval do
          remove_possible_method(name)
          define_method(name) { val }
        end

        val
      end
    end
  end

  # Removes a method if it is defined.
  def remove_possible_method(method)
    if method_defined?(method) || private_method_defined?(method)
      undef_method(method)
    end
  end
end
