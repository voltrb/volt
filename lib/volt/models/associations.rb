module Volt
  module Associations
    module ClassMethods
      def belongs_to(method_name, key_name=nil)
        define_method(method_name) do
          # Get the root node
          root = persistor.try(:root_model) || $page.page

          # Lookup the associated model id
          lookup_key = send(:"_#{key_name || method_name}_id")

          # Return a promise for the belongs_to
          root.send(:"_#{method_name.pluralize}").where(:_id => lookup_key).fetch_first
        end
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end
  end
end