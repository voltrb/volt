require 'volt/reactive/reactive_array'
require 'volt/models/model_wrapper'
require 'volt/models/model_helpers/model_helpers'
require 'volt/models/state_manager'
require 'volt/models/state_helpers'
require 'volt/data_stores/data_store'

module Volt
  class ArrayModel < ReactiveArray
    include ModelWrapper
    include ModelHelpers
    include StateManager
    include StateHelpers

    attr_reader :parent, :path, :persistor, :options, :array

    # For many methods, we want to register a dependency on the root_dep as soon
    # as the method is called, so it can begin loading.  Also, some persistors
    # need to have special loading logic (such as returning a promise instead
    # of immediately returning).  To accomplish this, we call the
    # #run_once_loaded method on the persistor.
    def self.proxy_with_load(*method_names)
      method_names.each do |method_name|
        old_method_name = :"__old_#{method_name}"
        alias_method(old_method_name, method_name)

        define_method(method_name) do |*args, &block|
          # track on the root dep
          persistor.try(:root_dep).try(:depend)

          if persistor.respond_to?(:run_once_loaded) &&
              !Volt.in_mode?(:no_model_promises)
            persistor.run_once_loaded(block) do
              send(old_method_name, *args)
            end
          else
            send(old_method_name, *args)
          end
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

    proxy_to_persistor :then, :fetch, :fetch_first, :fetch_each

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

    def state_for(*args)
      # Track on root dep
      persistor.try(:root_dep).try(:depend)

      super
    end

    # Make sure it gets wrapped
    def <<(model)
      if model.is_a?(Model)
        # Set the new path and the persistor.
        model.options = @options.merge(path: @options[:path] + [:[]])
      else
        model = wrap_values([model]).first
      end

      if model.is_a?(Model) && !model.can_create?
        fail "permissions did not allow create for #{model.inspect}"
      end

      # Add it to the array and trigger any watches or on events.
      super(model)

      if @persistor
        promise = @persistor.added(model, @array.size - 1)
        if promise && promise.is_a?(Promise)
          return promise.then do

            # Mark the model as not new
            model.instance_variable_set('@new', false)

            # Mark the model as loaded
            model.change_state_to(:loaded_state, :loaded)

            # return the model
            model
          end.fail do |err|
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
      end

      # Return this model
      Promise.new.resolve(model)
    end

    # Works like << except it always returns a promise
    def append(model)
      # Wrap results in a promise
      Promise.new.resolve(nil).then do
        send(:<<, model)
      end
    end

    # Create does append with a default empty model
    def create(model={})
      append(model)
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

    def first
      self[0]
    end

    # Return the first item in the collection, or create one if one does not
    # exist yet.
    def first_or_create
      first.then do |item|
        if item
          item
        else
          create
        end
      end
    end

    def last
      self[-1]
    end

    def reverse
      super
    end

    # Return the model, on store, .all is proxied to wait for load and return
    # a promise.
    def all
      self
    end

    # returns a promise to fetch the first instance
    def fetch_first(&block)
      persistor = self.persistor

      if persistor && persistor.is_a?(Persistors::ArrayStore)
        # On array store, we wait for the result to be loaded in.
        promise = limit(1).fetch do |res|
          result = res.first

          result
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
      @size_dep.depend
      array = []
      Volt.run_in_mode(:no_model_promises) do
        attributes.size.times do |index|
          array << deep_unwrap(self[index])
        end
      end
      array
    end

    def inspect
      Computation.run_without_tracking do
        # Track on size
        @size_dep.depend
        str = "#<#{self.class}"
        # str += " state:#{loaded_state}"
        # str += " path:#{path.join('.')}" if path
        # str += " persistor:#{persistor.inspect}" if persistor
        str += " #{@array.inspect}>"

        str
      end
    end

    def buffer(attrs = {})
      model_path  = options[:path] + [:[]]
      model_klass = Volt::Model.class_at_path(model_path)

      new_options = options.merge(path: model_path, save_to: self, buffer: true).reject { |k, _| k.to_sym == :persistor }
      model       = model_klass.new(attrs, new_options)

      model
    end

    # We need to setup the proxy methods below where they are defined.
    proxy_with_load :first, :[], :size, :last, :reverse, :all, :to_a

  end
end
