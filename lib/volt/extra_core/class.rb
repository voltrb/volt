class Class
  # Provides a way to make class attributes that inherit.  Pass
  # in symbols for attribute names.  When the class attribute is accessed from
  # a sublcass, it will be duped.  This allows the children to receive the value
  # from their parent, but then change it only in the child.
  #
  # NOTE: This does not do a deep clone, so multi-nested values may be changed.
  def class_attribute(*attrs)
    attrs.each do |name|
      name = name.to_sym
      ivar = :"@#{name}"

      assigner = :"#{name}="
      define_singleton_method(assigner) do |val|
        instance_variable_set(ivar, val)
      end

      define_singleton_method(name) do
        if instance_variable_defined?(ivar)
          # Get the value from the instance variable
          val = instance_variable_get(ivar)
        else
          # Fetch from parent and dup
          if superclass.respond_to?(name)
            val = superclass.send(name)
          else
            val = nil
          end
          val = val.dup rescue val

          instance_variable_set(ivar, val)
        end

        val
      end
    end
  end
end
