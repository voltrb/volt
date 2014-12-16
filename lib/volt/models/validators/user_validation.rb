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
        # Setup a validation that
        validate do |old_model|
          unless Volt.user_id
            # Show an error that the user is not logged in
            next {key => ['requires a logged in user']}
          end

          if _user_id == nil
            # Assign the user_id for the first time
            send(:"_#{key}=", Volt.user_id)
          end

          # Lock the user_id so it can only be assigned once
          if changed?(key) && user_id_was != nil
            # No valid user, add an error
            next {key => ['can not be changed']}
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
      def permissions(&block)
        # Store the permissions block so we can run it in validations
        self.__permissions__ = block

        validate do
          @__deny_fields = []

          # Run the permissions
          instance_eval(&self.class.__permissions__)

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

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.class_attribute :__permissions__
    end

    def deny_write(*fields)
      if @__deny_fields
        @__deny_fields += fields.map(&:to_sym)
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
  end
end