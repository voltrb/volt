require 'volt/reactive/reactive_array'
require 'volt/models/model_wrapper'
require 'volt/models/model_helpers'
require 'volt/models/state_manager'
require 'volt/models/state_helpers'

module Volt
  class ArrayModel < ReactiveArray
    include ModelWrapper
    include ModelHelpers
    include StateManager
    include StateHelpers


    attr_reader :parent, :path, :persistor, :options, :array

    # For many methods, we want to call load data as soon as the model is interacted
    # with, so we proxy the method, then call super.
    def self.proxy_with_root_dep(*method_names)
      method_names.each do |method_name|
        define_method(method_name) do |*args|
          # track on the root dep
          persistor.try(:root_dep).try(:depend)

          super(*args)
        end
      end
    end

    # Some methods get passed down to the persistor.
    def self.proxy_to_persistor(*method_names)
      method_names.each do |method_name|
        define_method(method_name) do |*args, &block|
          if @persistor.respond_to?(method_name)
            @persistor.send(method_name, *args, &block)
          else
            fail "this model's persistance layer does not support #{method_name}, try using store"
          end
        end
      end
    end

    proxy_with_root_dep :[], :size, :first, :last, :state_for#, :limit, :find_one, :find
    proxy_to_persistor :find, :where, :skip, :sort, :limit, :then, :fetch, :fetch_first

    def initialize(array = [], options = {})
      @options   = options
      @parent    = options[:parent]
      @path      = options[:path] || []
      @persistor = setup_persistor(options[:persistor])

      array = wrap_values(array)

      super(array)

      if @persistor
        @persistor.loaded
      else
        change_state_to(:loaded_state, :loaded, false)
      end
    end

    def attributes
      self
    end

    # Make sure it gets wrapped
    def <<(model)
      if model.is_a?(Model)
        # Set the new path
        model.options = @options.merge(path: @options[:path] + [:[]])
      else
        model = wrap_values([model]).first
      end

      if model.is_a?(Model) && !model.can_create?
        raise "permissions did not allow create for #{model.inspect}"
      end

      super(model)

      if @persistor
        promise = @persistor.added(model, @array.size - 1)
        if promise && promise.is_a?(Promise)
          return promise.fail do |err|
            # remove from the collection because it failed to save on the server
            @array.delete(model)

            # TODO: the model might be in at a different position already, so we should use a full delete
            trigger_removed!(@array.size - 1)
            trigger_size_change!
            #
            # re-raise, err might not be an Error object, so we use a rejected promise to re-raise
            Promise.new.reject(err)
          end
        end
      else
        nil
      end
    end

    # Works like << except it always returns a promise
    def append(model)
      # Wrap results in a promise
      Promise.new.resolve(nil).then do
        send(:<<, model)
      end
    end

    def delete(val)
      # Check to make sure the models are allowed to be deleted
      if !val.is_a?(Model) || val.can_delete?
        result = super
        Promise.new.resolve(result)
      else
        Promise.new.reject("permissions did not allow delete for #{val.inspect}.")
      end
    end

    # Find one does a query, but only returns the first item or
    # nil if there is no match.  Unlike #find, #find_one does not
    # return another cursor that you can call .then on.
    def find_one(*args, &block)
      find(*args, &block).limit(1)[0]
    end

    def first
      self[0]
    end

    # returns a promise to fetch the first instance
    def fetch_first(&block)
      persistor = self.persistor

      if persistor && persistor.is_a?(Persistors::ArrayStore)
        # On array store, we wait for the result to be loaded in.
        promise = limit(1).fetch do |res|
          result = res.first

          next result
        end
      else
        # On all other persistors, it should be loaded already
        promise = Promise.new.resolve(first)
      end

      # Run any passed in blocks after fetch
      promise = promise.then(&block) if block

      promise
    end

    # Make sure it gets wrapped
    def inject(*args)
      args = wrap_values(args)
      super(*args)
    end

    # Make sure it gets wrapped
    def +(*args)
      args = wrap_values(args)
      super(*args)
    end

    def new_model(*args)
      Volt::Model.class_at_path(options[:path]).new(*args)
    end

    def new_array_model(*args)
      ArrayModel.new(*args)
    end

    # Convert the model to an array all of the way down
    def to_a
      array = []
      attributes.each do |value|
        array << deep_unwrap(value)
      end
      array
    end

    def inspect
      Computation.run_without_tracking do
        # Track on size
        @size_dep.depend
        str = "#<#{self.class}:#{object_id} #{loaded_state}"
        str += " path:#{path.join('.')}" if path
        # str += " persistor:#{persistor.inspect}" if persistor
        str += " #{@array.inspect}>"

        str
      end
    end

    def buffer
      model_path  = options[:path] + [:[]]
      model_klass = Volt::Model.class_at_path(model_path)

      new_options = options.merge(path: model_path, save_to: self, buffer: true).reject { |k, _| k.to_sym == :persistor }
      model       = model_klass.new({}, new_options)

      model
    end

    private

    # Takes the persistor if there is one and
    def setup_persistor(persistor)
      if persistor
        @persistor = persistor.new(self)
      end
    end
  end
end
