module ReactiveAccessors

  module ClassMethods
    # Create a method to read a reactive value from an instance value.  If it
    # is not setup, create it so it can be updated through the reactive value
    # at a later point.
    def __reactive_dependency_get(var_name)
      value_dep = instance_variable_get(:"@__#{var_name}_dependency")
      value_dep ||= instance_variable_set(:"@__#{var_name}_dependency", Dependency.new)
    end

    def reactive_reader(*names)
      names.each do |name|
        var_name = :"@#{name}"
        define_method(name.to_sym) do
          value = instance_variable_get(var_name)

          self.class.__reactive_dependency_get(name).depend

          value
        end
      end
    end

    def reactive_writer(*names)
      names.each do |name|
        var_name = :"@#{name}"
        define_method(:"#{name}=") do |new_value|
          instance_variable_set(var_name, new_value)

          self.class.__reactive_dependency_get(name).changed!
        end
      end
    end

    def reactive_accessor(*names)
      reactive_reader(*names)
      reactive_writer(*names)
    end
  end

  def self.included(base)
    base.send :extend, ClassMethods
  end
end