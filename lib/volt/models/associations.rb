module Volt
  module Associations
    module ClassMethods
      def belongs_to(method_name, options = {})
        collection  ||= options.fetch(:collection, method_name).pluralize
        foreign_key ||= options.fetch(:foreign_key, :id)
        local_key   ||= options.fetch(:local_key, "#{method_name}_id")

        # Add a field for the association_id
        field(local_key)

        # getter
        define_method(method_name) do
          association_with_root_model('belongs_to') do |root|
            # Lookup the associated model id
            lookup_key = get(local_key)

            # Return a promise for the belongs_to
            root.get(collection).where(foreign_key => lookup_key).first
          end
        end

        define_method(:"#{method_name}=") do |obj|
          id = obj.is_a?(Fixnum) ? obj : obj.id

          # Assign the current model's something_id to the object's id
          set(local_key, id)
        end
      end

      def has_many(method_name, options = {})
        collection  ||= options.fetch(:collection, method_name).pluralize

        # Use the underscored current class name as the something_id.
        foreign_key ||= options.fetch(:foreign_key, "#{to_s.underscore.singularize}_id")
        local_key   ||= options.fetch(:local_key, :id)

        define_method(method_name) do
          lookup_key = get(local_key)
          array_model = root.get(collection).where(foreign_key => lookup_key)

          # Since we are coming off of the root collection, we need to setup
          # the right parent and path.
          new_path = array_model.options[:path]
          # Assign path and parent
          array_model.path = self.path + new_path
          array_model.parent = self

          array_model
        end
      end

      # has_one creates a method on the Volt::Model that returns a promise
      # to get the associated model.
      def has_one(method_name)
        if method_name.plural?
          raise NameError, "has_one takes a singluar association name"
        end

        define_method(method_name) do
          association_with_root_model('has_one') do |root|
            key = self.class.to_s.underscore + '_id'
            root.send(method_name.pluralize).where(key => id).first
          end
        end
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end

    private

    # Currently the has_many and belongs_to associations only work on the store collection,
    # this method checks to make sure we are on store and returns the root reference to it.
    def association_with_root_model(method_name)
      persistor = self.persistor || (respond_to?(:save_to) && save_to && save_to.persistor)

      # Check if we are on the store collection
      if persistor.is_a?(Volt::Persistors::ModelStore) ||
         persistor.is_a?(Volt::Persistors::Page)
        # Get the root node
        root = persistor.try(:root_model)

        # Yield to the block passing in the root node
        yield(root)
      else
        # raise an error about the method not being supported on this collection
        fail "#{method_name} currently only works on the store and page collection (support for other collections coming soon)"
      end
    end
  end
end
