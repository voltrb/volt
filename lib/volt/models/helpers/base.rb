module Volt
  module Models
    module Helpers
      # A place for things shared between an ArrayModel and a Model
      module Base
        def deep_unwrap(value)
          if value.is_a?(Model)
            value.to_h
          elsif value.is_a?(ArrayModel)
            value.to_a
          else
            value
          end
        end

        # Pass to the persisotr
        def event_added(event, first, first_for_event)
          @persistor.event_added(event, first, first_for_event) if @persistor
        end

        # Pass to the persistor
        def event_removed(event, last, last_for_event)
          @persistor.event_removed(event, last, last_for_event) if @persistor
        end

        ID_CHARS = [('a'..'f'), ('0'..'9')].map(&:to_a).flatten

        # Create a random unique id that can be used as the mongo id as well
        def generate_id
          id = []
          24.times { id << ID_CHARS.sample }

          id.join
        end


        # Return the attributes that are only for this model and any hash sub models
        # but not any sub-associations.
        def self_attributes
          # Don't store any sub-models, those will do their own saving.
          attributes.reject { |k, v| v.is_a?(ArrayModel) }.map do |k,v|
            if v.is_a?(Model)
              v = v.self_attributes
            end

            [k,v]
          end.to_h
        end


        # Takes the persistor if there is one and
        def setup_persistor(persistor)
          # Use page as the default persistor
          persistor ||= Persistors::Page
          if persistor.respond_to?(:new)
            @persistor = persistor.new(self)
          else
            # an already initialized persistor was passed in
            @persistor = persistor
          end
        end

        def store
          Volt.current_app.store
        end

        # returns the root model for the collection the model is currently on.  So
        # if the model is persisted somewhere on store, it will return ```store```
        def root
          persistor.try(:root_model)
        end

        module ClassMethods
          # Gets the class for a model at the specified path.
          def class_at_path(path)
            if path
              begin
                # remove the _ and then singularize/pluralize
                if path.last == :[]
                  index = -2
                else
                  index = -1
                end

                # process_class_name is defined by Model/ArrayModel as
                # singularize/pluralize
                klass_name = process_class_name(klass_name = path[index]).camelize

                # Lookup the class
                klass = Object.const_get(klass_name)

                # Use it if it is a model
                klass = self unless klass < self
              rescue NameError => e
                # Ignore exception, just means the model isn't defined
                klass = self
              end
            else
              klass = self
            end

            klass
          end
        end

        def self.included(base)
          base.send :extend, ClassMethods
        end

      end
    end
  end
end
