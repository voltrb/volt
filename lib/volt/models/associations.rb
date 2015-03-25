module Volt
  module Associations
    module ClassMethods
      def belongs_to(method_name, key_name=nil)
        define_method(method_name) do
          persistor = self.persistor || (respond_to(:save_to) && save_to.persistor)
          # Check if we are on the store collection
          if persistor.is_a?(Volt::Persistors::ModelStore)
            # Get the root node
            root = persistor.try(:root_model) || $page.page

            # Lookup the associated model id
            lookup_key = send(:"_#{key_name || method_name}_id")

            # Return a promise for the belongs_to
            root.send(:"_#{method_name.pluralize}").where(:_id => lookup_key).fetch_first
          else
            fail "belongs_to currently only works on the store collection (support for other collections coming soon)"
          end
        end
      end

      def has_many(method_name, key_name=nil)
        persistor = self.persistor || (respond_to(:save_to) && save_to.persistor)

        # Check if we are on the store collection
        if persistor.is_a?(Volt::Persistors::ModelStore)

        else
          fail "has_many currently only works on the store collection (support for other collections coming soon)"
        end
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end
  end
end