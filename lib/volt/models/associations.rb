module Volt
  module Associations
    module ClassMethods
      def belongs_to(method_name, key_name=nil)
        define_method(method_name) do
          association_with_root_model('belongs_to') do |root|
            # Lookup the associated model id
            lookup_key = send(:"_#{key_name || method_name}_id")

            # Return a promise for the belongs_to
            root.send(:"_#{method_name.pluralize}").where(:_id => lookup_key).fetch_first
          end
        end
      end

      def has_many(method_name, remote_key_name=nil)
        define_method(method_name) do
          association_with_root_model('has_many') do |root|
            id = self._id

            # The key will be "{this class name}_id"
            remote_key_name ||= :"#{path[-2].singularize}_id"

            root.send(:"_#{method_name.pluralize}").where(remote_key_name => id)
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
      persistor = self.persistor || (respond_to(:save_to) && save_to.persistor)

      # Check if we are on the store collection
      if persistor.is_a?(Volt::Persistors::ModelStore)
        # Get the root node
        root = persistor.try(:root_model)

        # Yield to the block passing in the root node
        yield(root)
      else
        # raise an error about the method not being supported on this collection
        fail "#{method_name} currently only works on the store collection (support for other collections coming soon)"
      end
    end
  end
end