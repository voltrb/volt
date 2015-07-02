module Volt
  class UniqueValidator
    def self.validate(model, field_name, args)
      if RUBY_PLATFORM != 'opal'
        if args
          value  = model.get(field_name)

          query = {}
          # Check to see if any other documents have this value.
          query[field_name.to_s] = value
          query['id'] = { '$ne' => model.id }

          # Check if the value is taken
          # TODO: need a way to handle scope for unique
          return Volt.current_app.store.get(model.path[-2]).where(query).first.then do |item|
            if item
              message = (args.is_a?(Hash) && args[:message]) || 'is already taken'

              # return the error
              next { field_name => [message] }
            end
          end
        end
      end

      # no errors
      {}
    end
  end
end
