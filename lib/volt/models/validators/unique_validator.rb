module Volt
  class UniqueValidator
    def self.validate(model, field_name, args)
      errors = {}

      if RUBY_PLATFORM != 'opal'
        if args
          value  = model.read_attribute(field_name)

          query = {}
          query[field_name[1..-1]] = value
          puts "Check Query: #{query.inspect}"

          # Check if the value is taken
          # if model.parent.find(query).size > 0
          if Volt.server? || $page.store.send(:"_#{path[-2]}").find(query).size > 0
            puts "Taken!"
            errors[field_name] = ["is already taken"]
          end
        end
      end

      errors
    end
  end
end
