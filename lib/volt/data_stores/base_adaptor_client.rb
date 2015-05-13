module Volt
  class DataStore
    class BaseAdaptorClient
      # normalize_query should take all parts of the query and return a
      # "normalized" version, so that two queries that are eseitnally the same
      # except for things like order are the same.
      #
      # Typically this means sorting parts of the query so that two queries
      # which do the same things are the same, so they can be uniquely
      # identified.
      #
      # The default implementation does no normalizing.  This works, but results
      # in more queries being sent to the backend.
      def self.normalize_query(query)
        query
      end

      # A class method that takes an array of method names we want to provide
      # on the ArrayModel class.  (These are typically query/sort/order/etc...
      # methods).  This adds a proxy method to the store persistor for all
      # passed in method names, and then sets up a default tracking method
      # on the ArrayStore persistor.
      def self.data_store_methods(*method_names)
        Volt::ArrayModel.proxy_to_persistor(*method_names)

        method_names.each do |method_name|
          Volt::Persistors::ArrayStore.send(:define_method, method_name) do |*args|
            add_query_part(method_name, *args)
          end
        end
      end
    end
  end
end
