module Volt
  class UniqueValidator
    def self.validate(model, field_name, args)
      errors = {}

      puts "Unique Validate: #{args.inspect}"

      if RUBY_PLATFORM != 'opal'
        if args
          value  = model.send(field_name)

          query = {}
          query[field_name[1..-1]] = value
          puts "Check Query: #{query.inspect}"

          puts "REsULTS: #{model.parent.find(query).size.inspect}"
          # Check if the value is taken
          if model.parent.find(query).size > 0
            puts "Taken!"
            errors[field_name[1..-1]] = ["is already taken"]
          end
        end
      end

      puts "ERRORS: #{errors.inspect}"
      errors
    end
  end
end
