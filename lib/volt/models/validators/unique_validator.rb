module Volt
  class UniqueValidator
    def self.validate(model, old_model, field_name, args)
      errors = {}

      if RUBY_PLATFORM != 'opal'
        if args
          value  = model.read_attribute(field_name)

          query = {}
          # Check to see if any other documents have this value.
          query[field_name.to_s] = value
          query['_id'] = { '$ne' => model._id }

          # Check if the value is taken
          # TODO: need a way to handle scope for unique
          if $page.store.send(:"_#{model.path[-2]}").find(query).size > 0
            message = (args.is_a?(Hash) && args[:message]) || 'is already taken'

            errors[field_name] = [message]
          end
        end
      end

      errors
    end
  end
end
