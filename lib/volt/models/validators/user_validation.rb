module Volt
  # Provide methods on the model class to more easily setup user validations
  module UserValidatorHelpers
    module ClassMethods
      # Own by user requires a logged in user (Volt.user) to save a model.  If
      # the user is not logged in, an validation error will occur.  Once created
      # the user can not be changed.
      #
      # @param key [Symbol] the name of the attribute to store
      def own_by_user(key=:user_id)
        # When the model is created, assign it the user_id (if the user is logged in)
        on(:new) do
          if (user_id = Volt.user_id)
            send(:"_#{key}=", user_id)
          end
        end

        on(:create, :update) do
          # Don't allow the key to be changed
          deny(key)
        end

        # Setup a validation that requires a user_id
        validate do
          unless _user_id
            # Show an error that the user is not logged in
            next {key => ['requires a logged in user']}
          end
        end
      end


      # TODO: Change to
      # permissions(:create, :read, :update) do |action|
      #   if owner?
      #     allow
      #   else
      #     deny :user_id
      #   end
      # end

      # permissions takes a block and yields
      def permissions(*actions, &block)
        # Store the permissions block so we can run it in validations
        self.__permissions__ ||= {}

        # if no action was specified, assume all actions
        actions += [:create, :read, :update, :delete] if actions.size == 0

        actions.each do |action|
          # Add to an array of proc's for each action
          (self.__permissions__[action] ||= []) << block
        end

        validate do
          run_permissions
        end
      end
    end

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.class_attribute :__permissions__
    end

    def deny(*fields)
      if @__deny_fields
        if @__deny_fields != true
          if fields.size == 0
            # No field's were passed, this means we deny all
            @__deny_fields = true
          else
            # Fields were specified, add them to the list
            @__deny_fields += fields.map(&:to_sym)
          end
        end
      else
        raise "deny_write should be called inside of a permissions block"
      end
    end

    # owner? can be called on a model to check if the currently logged
    # in user (```Volt.user```) is the owner of this instance.
    #
    # @param key [Symbol] the name of the attribute where the user_id is stored
    def owner?(key=:user_id)
      send(:"_#{key}") == Volt.user_id
    end

    private
    def run_permissions
      @__deny_fields = []

      # Run the permission blocks
      action_name = new? ? :create : :update

      # Run each of the permission blocks for this action
      if (blocks = self.class.__permissions__[action_name])
        blocks.each do |block|
          instance_eval(&block)
        end
      end

      errors = {}

      @__deny_fields.each do |deny_field|
        if changed?(deny_field)
          (errors[deny_field] ||= []) << 'can not be changed'
        end
      end

      @__deny_fields = nil

      errors
    end
  end
end
