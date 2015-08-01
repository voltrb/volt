require 'volt/reactive/reactive_array'
require 'volt/models/model_wrapper'
require 'volt/models/helpers/base'
require 'volt/models/state_manager'
require 'volt/models/helpers/array_model'
require 'volt/data_stores/data_store'

module Volt
  class RecordNotFoundException < Exception ; end

  class ArrayModel < ReactiveArray
    include ModelWrapper
    include Models::Helpers::Base
    include StateManager
    include Models::Helpers::ArrayModel

    attr_reader :parent, :path, :persistor, :options, :array

    # For many methods, we want to register a dependency on the root_dep as soon
    # as the method is called, so it can begin loading.  Also, some persistors
    # need to have special loading logic (such as returning a promise instead
    # of immediately returning).  To accomplish this, we call the
    # #run_once_loaded method on the persistor.
    def self.proxy_with_load(*method_names)
      imethods = instance_methods(false)
      method_names.each do |method_name|
        # Sometimes we want to alias a method_missing method, so we use super
        # instead to call it, if its not defined locally.
        if imethods.include?(method_name)
          imethod = true
          old_method_name = :"__old_#{method_name}"
          alias_method(old_method_name, method_name)
        else
          imethod = false
        end

        define_method(method_name) do |*args, &block|
          if imethod
            call_orig = proc do |*args|
              send(old_method_name, *args)
            end
          else
            call_orig = proc do |*args|
              super(*args)
            end
          end

          # track on the root dep
          persistor.try(:root_dep).try(:depend)

          if persistor.respond_to?(:run_once_loaded) &&
              !Volt.in_mode?(:no_model_promises)
            promise = persistor.run_once_loaded.then do
              # We are already loaded and the result is going to be wrapped
              Volt.run_in_mode(:no_model_promises) do
                call_orig.call(*args)
              end
            end

            if block
              promise = promise.then do |val|
                block.call(val)
              end
            end

            promise
          else
            call_orig.call(*args)
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
      @persistor = setup_persistor(options[:persistor])

      array = wrap_values(array)

      super(array)

      if @persistor
        @persistor.loaded
      else
        change_state_to(:loaded_state, :loaded, false)
      end
    end

    def parent=(val)
      @options[:parent] = val
    end

    def parent
      @options[:parent]
    end

    def path
      @options[:path] || []
    end

    def path=(val)
      @options[:path] = val
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
      create_new_model(model, :<<)
    end

    # Alias append for use inside of child append
    alias_method :reactive_array_append, :append
    # Works like << except it always returns a promise
    def append(model)
      create_new_model(model, :append)
    end

    # Create does append with a default empty model
    def create(model={})
      create_new_model(model, :create)
    end


    def delete(val)
      # Check to make sure the models are allowed to be deleted
      if !val.is_a?(Model)
        # Not a model, return as a Promise
        super(val).then
      else
        val.can_delete?.then do |can_delete|
          if can_delete
            super(val)
          else
           Promise.new.reject("permissions did not allow delete for #{val.inspect}.")
          end
        end
      end
    end

    def first
      if persistor.is_a?(Persistors::ArrayStore)
        limit(1)[0]
      else
        self[0]
      end
    end

    # Same as first, except it returns a promise (even on page collection), and
    # it fails with a RecordNotFoundException if no result is found.
    def first!
      fail_not_found_if_nil(first)
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
      @size_dep.depend
      @array.reverse
    end

    # Array#select, with reactive notification
    def select
      new_array = []
      @array.size.times do |index|
        value = @array[index]
        if yield(value)
          new_array << value
        end
      end

      new_array
    end

    # Return the model, on store, .all is proxied to wait for load and return
    # a promise.
    def all
      self
    end

    # returns a promise to fetch the first instance
    def fetch_first(&block)
      Volt.logger.warn('.fetch_first is deprecated in favor of .first')
      first
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

    def flatten(*args)
      wrap_values(to_a.flatten(*args))
    end

    def new_model(*args)
      Volt::Model.class_at_path(options[:path]).new(*args)
    end
    alias_method :new, :new_model

    def new_array_model(*args)
      Volt::ArrayModel.class_at_path(options[:path]).new(*args)
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

    def to_json
      array = to_a

      if array.is_a?(Promise)
        array.then(&:to_json)
      else
        array.to_json
      end
    end


    def inspect
      # Track on size
      @size_dep.depend
      str = "#<#{self.class}"
      # str += " state:#{loaded_state}"
      # str += " path:#{path.join('.')}" if path
      # str += " persistor:#{persistor.inspect}" if persistor
      str += " #{@array.inspect}>"

      str
    end

    def buffer(attrs = {})
      model_path  = options[:path] + [:[]]
      model_klass = Volt::Model.class_at_path(model_path)

      new_options = options.merge(path: model_path, save_to: self, buffer: true).reject { |k, _| k.to_sym == :persistor }
      model       = model_klass.new(attrs, new_options)

      model
    end

    # Raise a RecordNotFoundException if the promise returns a nil.
    def fail_not_found_if_nil(promise)
      promise.then do |val|
        if val
          val
        else
          raise RecordNotFoundException.new
        end
      end
    end

    def self.process_class_name(name)
      name.pluralize
    end

    alias_method :reactive_count, :count
    def count(&block)
      all.reactive_count(&block)
    end

    private
    # called form <<, append, and create.  If a hash is passed in, it converts
    # it to a model.  Then it takes the model and inserts it into the ArrayModel
    # then persists it.
    def create_new_model(model, from_method)
      if model.is_a?(Model)
        if model.buffer?
          fail "The #{from_method} does not take a buffer.  Call .save! on buffer's to persist them."
        end

        # Set the new path and the persistor.
        model.options = @options.merge(parent: self, path: @options[:path] + [:[]])
      else
        model = wrap_values([model]).first
      end


      if model.is_a?(Model)
        promise = model.can_create?.then do |can_create|
          unless can_create
            fail "permissions did not allow create for #{model.inspect}"
          end
        end.then do

          # Add it to the array and trigger any watches or on events.
          reactive_array_append(model)

          @persistor.added(model, @array.size - 1)
        end.then do
          nil.then do
            # Validate and save
            model.run_changed
          end.then do
            # Mark the model as not new
            model.instance_variable_set('@new', false)

            # Mark the model as loaded
            model.change_state_to(:loaded_state, :loaded)

          end.fail do |err|
            # remove from the collection because it failed to save on the server
            # we don't need to call delete on the server.
            index = @array.index(model)
            delete_at(index, true)

            # remove from the id list
            @persistor.try(:remove_tracking_id, model)

            # re-raise, err might not be an Error object, so we use a rejected promise to re-raise
            Promise.new.reject(err)
          end
        end
      else
        promise = nil.then do
          # Add it to the array and trigger any watches or on events.
          reactive_array_append(model)

          @persistor.added(model, @array.size - 1)
        end
      end

      promise = promise.then do
        # resolve the model
        model
      end

      # unwrap the promise if the persistor is synchronus.
      # This will return the value or raise the exception.
      promise = promise.unwrap unless @persistor.async?

      # return
      promise
    end

    # We need to setup the proxy methods below where they are defined.
    proxy_with_load :[], :size, :length, :last, :reverse, :all, :to_a, :empty?, :present?, :blank?

  end
end
