module Volt
  # Provide methods on the model class to more easily setup user validations
  module UserValidatorHelpers
    module ClassMethods
      # Own by user assigns a user_id to
      def own_by_user(key=:user_id)
        # Setup a validation that
        validate do |old_model|
          if _user_id == nil && Volt.user_id
            send(:"_#{key}=", Volt.user_id)
          end
          # Lock the user_id so it can only be assigned once
          if changed?(key) && user_id_was != nil
            # No valid user, add an error
            next {key => ['requires a logged in user']}
          end
        end
      end

      # permissions takes a block and yields
      def permissions(&block)
        self.__permissions__ = block

        validate do
          @__deny_fields = []

          # Run the permissions
          instance_eval(&self.class.__permissions__)

          errors = {}
          @__deny_fields.each do |deny_field|
            if changed?(deny_field)
              errors[deny_field] ||= []
              errors[deny_field] << 'can not be changed'
            end
          end

          errors
        end
      end
    end

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.class_attribute :__permissions__
    end

    def deny_write(*fields)
      @__deny_fields += fields.map(&:to_sym)
    end

    def owner?(key=:user_id)
      send(:"_#{key}") == Volt.user_id
    end
  end
end