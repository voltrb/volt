module ReactiveAccessors

  module ClassMethods
    # Create a method to read a reactive value from an instance value.  If it
    # is not setup, create it so it can be updated through the reactive value
    # at a later point.
    def reactive_reader(*names)
      names.each do |name|
        var_name = :"@#{name}"
        define_method(name.to_sym) do
          value = instance_variable_get(var_name)

          unless value
            value = ReactiveValue.new(nil)

            instance_variable_set(var_name, value)
          end

          value
        end
      end
    end

    def reactive_writer(*names)
      names.each do |name|
        var_name = :"@#{name}"
        define_method(:"#{name}=") do |new_value|
          value = instance_variable_get(var_name)

          if value
            value.cur = new_value
          else
            instance_variable_set(var_name, ReactiveValue.new(value))
          end
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