require 'volt/models/model_wrapper'
require 'volt/models/array_model'
require 'volt/models/helpers/base'
require 'volt/models/model_hash_behaviour'
require 'volt/models/validations/validations'
require 'volt/utils/modes'
require 'volt/models/state_manager'
require 'volt/models/helpers/model'
require 'volt/models/buffer'
require 'volt/models/field_helpers'
require 'volt/reactive/reactive_hash'
require 'volt/models/validators/user_validation'
require 'volt/models/helpers/dirty'
require 'volt/models/helpers/listener_tracker'
require 'volt/models/helpers/change_helpers'
require 'volt/models/permissions'
require 'volt/models/associations'
require 'volt/reactive/class_eventable'
require 'volt/utils/event_counter'
require 'volt/reactive/reactive_accessors'
require 'volt/utils/lifecycle_callbacks'
require 'thread'

module Volt
  class NilMethodCall < NoMethodError
  end

  # The error is raised when a reserved field name is used in a
  # volt model.
  class InvalidFieldName < StandardError
  end

  class Model
    include LifecycleCallbacks
    include ModelWrapper
    include Models::Helpers::Base
    include ModelHashBehaviour
    include StateManager
    include Models::Helpers::Model
    include Validations
    # Buffer needs to go after StateHelpers so it can call saved_state as super
    include Buffer
    include FieldHelpers
    include UserValidatorHelpers
    include Models::Helpers::Dirty
    include ClassEventable
    include Modes
    include Models::Helpers::ListenerTracker
    include Permissions
    include Associations
    include ReactiveAccessors
    include Models::Helpers::ChangeHelpers

    attr_reader :attributes, :parent, :path, :persistor, :options

    INVALID_FIELD_NAMES = {
      attributes: true,
      parent: true,
      path: true,
      options: true,
      persistor: true
    }

    def initialize(attributes = {}, options = {}, initial_state = nil)
      # Start off with empty attributes
      @attributes = {}

      # The listener event counter keeps track of how many computations are listening on this model
      @listener_event_counter = EventCounter.new(
        -> { parent.try(:persistor).try(:listener_added) },
        -> { parent.try(:persistor).try(:listener_removed) }
      )

      # The root dependency is used to track if anything is using the data from this
      # model.  That information is relayed to the ArrayModel so it knows when it can
      # stop subscribing.
      # @root_dep    = Dependency.new(@listener_event_counter.method(:add), @listener_event_counter.method(:remove))
      @root_dep    = Dependency.new(-> { retain }, -> { release })

      @deps        = HashDependency.new
      @size_dep    = Dependency.new
      self.options = options

      @new = (initial_state != :loaded)

      assign_attributes(attributes, true)

      # The persistor is usually responsible for setting up the loaded_state, if
      # there is no persistor, we set it to loaded
      if @persistor
        @persistor.loaded(initial_state)
      else
        change_state_to(:loaded_state, initial_state || :loaded, false)
      end

      # Trigger the new event, pass in :new
      trigger!(:new, :new)
    end

    def retain
      @listener_event_counter.add
    end

    def release
      @listener_event_counter.remove
    end

    def state_for(*args)
      @root_dep.depend
      super
    end

    def id
      get(:id)
    end

    def id=(val)
      set(:id, val)
    end

    def _id
      get(:id)
    end

    # Return true if the model hasn't been saved yet
    def new?
      @new
    end

    # Update the options
    def options=(options)
      @options     = options
      @parent      = options[:parent]
      @path        = options[:path] || []
      @class_paths = options[:class_paths]
      @persistor   = setup_persistor(options[:persistor])
    end

    # Assign multiple attributes as a hash, directly.
    def assign_attributes(attrs, initial_setup = false, skip_changes = false)
      attrs = wrap_values(attrs)

      if attrs
        # When doing a mass-assign, we don't validate or save until the end.
        if initial_setup || skip_changes
          Model.no_change_tracking do
            assign_all_attributes(attrs, skip_changes)
          end
        else
          assign_all_attributes(attrs)
        end
      else
        # Assign to empty
        @attributes = {}
      end

      # Trigger and change all
      @deps.changed_all!
      @deps = HashDependency.new

      run_initial_setup(initial_setup)
    end

    alias_method :attributes=, :assign_attributes

    # Pass the comparison through
    def ==(val)
      if val.is_a?(Model)
        # Use normal comparison for a model
        super
      else
        # Compare to attributes otherwise
        attributes == val
      end
    end

    # Pass through needed
    def !
      !attributes
    end

    def method_missing(method_name, *args, &block)
      if method_name[0] == '_'
        # Remove underscore
        method_name = method_name[1..-1]
        if method_name[-1] == '='
          # Assigning an attribute without the =
          set(method_name[0..-2], args[0], &block)
        else
          # If the method has an ! on the end, then we assign an empty
          # collection if no result exists already.
          expand = (method_name[-1] == '!')
          method_name = method_name[0..-2] if expand

          get(method_name, expand)
        end
      else
        # Call on parent
        super
      end
    end

    # Do the assignment to a model and trigger a changed event
    def set(attribute_name, value, &block)
      # Assign, without the =
      attribute_name = attribute_name.to_sym

      check_valid_field_name(attribute_name)

      old_value = @attributes[attribute_name]
      new_value = wrap_value(value, [attribute_name])

      if old_value != new_value
        # Track the old value, skip if we are in no_validate
        attribute_will_change!(attribute_name, old_value) unless Volt.in_mode?(:no_change_tracking)

        # Assign the new value
        @attributes[attribute_name] = new_value

        @deps.changed!(attribute_name)

        @size_dep.changed! if old_value.nil? || new_value.nil?

        # TODO: Can we make this so it doesn't need to be handled for non store collections
        # (maybe move it to persistor, though thats weird since buffers don't have a persistor)
        clear_server_errors(attribute_name) if @server_errors.present?

        # Save the changes
        run_changed(attribute_name) unless Volt.in_mode?(:no_change_tracking)
      end

      new_value
    end

    # When reading an attribute, we need to handle reading on:
    # 1) a nil model, which returns a wrapped error
    # 2) reading directly from attributes
    # 3) trying to read a key that doesn't exist.
    def get(attr_name, expand = false)
      # Reading an attribute, we may get back a nil model.
      attr_name = attr_name.to_sym

      check_valid_field_name(attr_name)

      # Track that something is listening
      @root_dep.depend

      # Track dependency
      @deps.depend(attr_name)

      # See if the value is in attributes
      if @attributes && @attributes.key?(attr_name)
        return @attributes[attr_name]
      else
        # If we're expanding, or the get is for a collection, in which
        # case we always expand.
        plural_attr = attr_name.plural?
        if expand || plural_attr
          new_value = read_new_model(attr_name)

          # A value was generated, store it
          if new_value
            # Assign directly.  Since this is the first time
            # we're loading, we can just assign.
            #
            # Don't track changes if we're setting a collection
            Volt.run_in_mode_if(plural_attr, :no_change_tracking) do
              set(attr_name, new_value)
            end
          end

          return new_value
        else
          return nil
        end
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.start_with?('_') || super
    end

    # Get a new model, make it easy to override
    def read_new_model(method_name)
      if @persistor && @persistor.respond_to?(:read_new_model)
        return @persistor.read_new_model(method_name)
      else
        opts = @options.merge(parent: self, path: path + [method_name])

        if method_name.plural?
          return new_array_model([], opts)
        else
          return new_model({}, opts)
        end
      end
    end

    def new_model(attributes = {}, new_options = {}, initial_state = nil)
      new_options = new_options.merge(persistor: @persistor)

      Volt::Model.class_at_path(new_options[:path]).new(attributes, new_options, initial_state)
    end

    def new_array_model(attributes, options)
      # Start with an empty query
      options         = options.dup
      options[:query] = []

      Volt::ArrayModel.class_at_path(options[:path]).new(attributes, options)
    end

    def inspect
      Computation.run_without_tracking do
        str = "#<#{self.class}"
        # str += ":#{object_id}"

        # First, select all of the non-ArrayModel values
        attrs = attributes.reject {|key, val| val.is_a?(ArrayModel) }.to_h

        # Show the :id first, then sort the rest of the attributes
        id = attrs.delete(:id)
        id = id[0..3] + '..' + id[-4..-1] if id

        attrs = attrs.sort
        attrs.insert(0, [:id, id]) if id

        str += attrs.map do |key, value|
          " #{key}: #{value.inspect}"
        end.join(',')
        str += '>'
        str
      end
    end

    def destroy
      if parent
        result = parent.delete(self)

        # Wrap result in a promise if it isn't one
        return result#.then
      else
        fail 'Model does not have a parent and cannot be deleted.'
      end
    end

    # Setup run mode helpers
    [:no_save, :no_validate, :no_change_tracking].each do |method_name|
      define_singleton_method(method_name) do |&block|
        Volt.run_in_mode(method_name, &block)
      end
    end

    def to_json
      to_h.to_json
    end

    # Update tries to update the model and returns
    def update(attrs)
      old_attrs = @attributes.dup
      Model.no_change_tracking do
        assign_all_attributes(attrs, false)

        validate!.then do |errs|
          if errs && errs.present?
            # Revert wholesale
            @attributes = old_attrs
            Promise.new.resolve(errs)
          else
            # Persist
            persist_changes(nil)
          end
        end
      end
    end

    private
    def run_initial_setup(initial_setup)
      # Save the changes
      if initial_setup
        # Run initial validation
        if Volt.in_mode?(:no_validate)
          # No validate, resolve self
          Promise.new.resolve(self)
        else
          return validate!.then do |errs|
            if errs && errs.size > 0
              Promise.new.reject(errs)
            else
              Promise.new.resolve(self)
            end
          end
        end
      else
        return run_changed
      end
    end


    # Volt provides a few access methods to get more data about the model,
    # we want to prevent these from being assigned or accessed through
    # underscore methods.
    def check_valid_field_name(name)
      if INVALID_FIELD_NAMES[name]
        fail InvalidFieldName, "`#{name}` is reserved and can not be used as a field"
      end
    end

    # Used internally from other methods that assign all attributes
    def assign_all_attributes(attrs, track_changes = false)
      # Assign each attribute using setters
      attrs.each_pair do |key, value|
        key = key.to_sym

        # Track the change, since assign_all_attributes runs with no_change_tracking
        old_val = @attributes[key]
        attribute_will_change!(key, old_val) if track_changes && old_val != value

        if self.respond_to?(:"#{key}=")
          # If a method without an underscore is defined, call that.
          send(:"#{key}=", value)
        else
          # Otherwise, use the _ version
          set(key, value)
        end
      end

      # Make an id if there isn't one yet
      if @attributes[:id].nil? && persistor.try(:auto_generate_id)
        @attributes[:id] = generate_id
      end
    end

    def self.inherited(subclass)
      if defined?(RootModels)
        RootModels.add_model_class(subclass)
      end
    end

    def self.process_class_name(name)
      name.singularize
    end

  end
end
