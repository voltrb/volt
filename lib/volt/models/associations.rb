module Volt
  module Associations
    module ClassMethods
      def belongs_to(method_name, options = {})
        collection, foreign_key, local_key = assoc_parts_and_track(
          method_name, options, :belongs_to
        )

        # Add a field for the association_id
        field(local_key, String)

        # getter
        define_method(method_name) do
          association_with_root_model('belongs_to') do |root|
            # Lookup the associated model id
            lookup_key = get(local_key)

            # Return a promise for the belongs_to
            root.get(collection).where(foreign_key => lookup_key).first
          end
        end

        # setter
        define_method(:"#{method_name}=") do |obj|
          # Associatie the obj's foreign key
          obj.set(foreign_key, id)

          # Associate on the method name
          set(method_name, obj)
        end
      end

      def has_many(method_name, options = {})
        mmethod_name = method_name.to_sym
        if method_name.singular?
          raise NameError, "has_many takes a plural association name"
        end

        collection, foreign_key, local_key = assoc_parts_and_track(
          method_name, options, :has_many
        )

        define_method(method_name) do
          # If the association is already in attributes, return
          if attributes[method_name]
            return get(method_name)
          end

          # Get the
          lookup_key = get(local_key)
          array_model = root.get(collection).where(foreign_key => lookup_key)

          # Since we are coming off of the root collection, we need to setup
          # the right parent and path.
          new_path = array_model.options[:path]
          # Assign path and parent
          array_model.path = self.path + new_path
          array_model.parent = self

          # Store the associated query, don't track changes, since the
          # association is persisted via _id fields.
          Volt.run_in_mode(:no_change_tracking) do
            set(method_name, array_model)
          end
          array_model
        end

        # setter
        # define_method(:"#{method_name}=") do |val|
        #   assoc = get(method_name)

        #   # Set the foreign_key on the has_many model to the local_key of the
        #   # current model.
        #   assoc.append(val).then do |model|
        #     model.set(foreign_key, get(local_key))
        #   end
        # end
      end

      # has_one creates a method on the Volt::Model that returns a promise
      # to get the associated model.
      def has_one(method_name, options={})
        if method_name.plural?
          raise NameError, "has_one takes a singluar association name"
        end

        collection, foreign_key, local_key = assoc_parts_and_track(
          method_name, options, :has_one
        )


        define_method(method_name) do
          association_with_root_model('has_one') do |root|
            key = self.class.to_s.underscore + '_id'
            root.send(method_name.pluralize).where(key => id).first
          end
        end
      end


      def assoc_parts(method_name, options, type)
        collection = options.fetch(:collection, method_name).pluralize

        default_foreign_key = case type
        when :has_many, :has_one
          :"#{to_s.underscore.singularize}_id"
        else
          :id
        end
        foreign_key = options.fetch(:foreign_key, default_foreign_key)

        default_local_key = case type
        when :belongs_to
          :"#{method_name}_id"
        else
          :id
        end

        local_key = options.fetch(:local_key, default_local_key)

        return collection, foreign_key, local_key
      end

      private
      def check_name_in_use(name)
        if self.fields[name]
          type = 'A field'
        elsif self.associations[name]
          type = 'An association'
        else
          type = nil
        end

        if type
          raise "#{type} is already defined for `#{name}` on `#{to_s}`"
        end
      end

      # Checks to make sure the association isn't in use, then generates the
      # collection, foreign_key, and local_key's based on the type and options.
      # Then tracks the association data on the model class.
      def assoc_parts_and_track(method_name, options, type)
        method_name = method_name.to_sym
        check_name_in_use(method_name)

        collection, foreign_key, local_key = assoc_parts(method_name, options,
                                                         type)

        # Track the association
        self.associations[method_name] = {
          type: type,
          to_many: type == :has_many,
          collection: collection,
          foreign_key: foreign_key,
          local_key: local_key
        }

        return collection, foreign_key, local_key
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
      base.class_attribute :associations
      base.associations = {}
    end

    # Associate takes an association name, and a model and changes the
    # association field (the foreign_key for has_one, has_many, or the local_key
    # for belongs_to).  This works for both explicit (has_many, has_one,
    # belongs_to) associations, and implicit (._items)
    def associate(method_name, model)
      assoc_data = self.class.associations[method_name]

      if assoc_data
        # Extract from association data
        collection, foreign_key, local_key, type =
          assoc_data.mfetch(:collection, :foreign_key, :local_key, :type)
      else
        # Association is implicit, generate instead
        type = :has_many
        collection, foreign_key, local_key =
          self.class.assoc_parts(method_name, {}, type)
      end

      case type
      when :has_many, :has_one
        model.set(foreign_key, get(local_key))
      else
        # belongs_to
        set(local_key, get(foreign_key))
      end
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
