# The Actions module adds helpers for setting up and using
# actions on a class.  You can setup helpers for an action with
#
#   setup_action_helpers_in_class(:before_action, :after_action)
#
# The above will setup before_action and after_action methods on
# the class.  Typically setup_action_helpers_in_class will be run
# in a base class.
#
#   before_action :require_login
module Volt
  module LifecycleCallbacks
    # StopChainException inherits from Exception directly so it will not be handled by a
    # default rescue.
    class StopChainException < Exception; end

    module ClassMethods
      # Takes a list of callbacks (as symbols).  A callback is typically used
      # for before/after actions, but can be used anytime you have callbacks
      # that may be filtered by action.  The method will create an callback
      # method for each callback name passed in.
      def setup_action_helpers_in_class(*callback_names)
        callback_names.each do |callback_name|
          # Setup a class attribute to track the
          callbacks_var_name = :"#{callback_name}_callbacks"
          class_attribute(callbacks_var_name)

          # Create the method on the class
          define_singleton_method(callback_name) do |*args, &block|
            # Add the block in place of the symbol
            args.unshift(block) if block

            fail 'No callback symbol or block provided' unless args[0]

            callbacks = send(callbacks_var_name)

            unless callbacks
              callbacks = []
              send(:"#{callbacks_var_name}=", callbacks)
            end

            if args.last.is_a?(Hash)
              options = args.pop
            else
              options = nil
            end

            args.each do |callback|
              callbacks << [callback, options]
            end
          end
        end
      end
    end

    # To run the callbacks on a class, call #run_callbacks passing in the
    # callback_name and the action it runs with.  If the callback chain was
    # stopped with #stop_chain, it will return true, otherwise false.
    def run_callbacks(callback_name, action=nil)
      callbacks = self.class.send(:"#{callback_name}_callbacks")

      callbacks ||= []
      if action
        callbacks = filter_actions_by_only_exclude(callbacks || [], action)
      end

      begin
        callbacks.map { |v| v[0] }.each do |callback|
          case callback
          when Symbol
            send(callback)
          when Proc
            instance_eval(&callback)
          end
        end

        return false
      rescue StopChainException => e
        return true
      end
    end

    # The stop chain method can be called inside of a callback and it will
    # raise an exception under the hood which will stop the chain and evaluation
    # from where stop_chain is called.
    def stop_chain
      fail StopChainException
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end

    private

    # TODO: currently we filter during the call, we could maybe improve performance
    # here by storing by action and having an all category as well.
    def filter_actions_by_only_exclude(callbacks, action)
      callbacks.select do |callback, options|
        if options && (only = options[:only])
          # If there is an only, make sure the action is in the list.
          [only].flatten.include?(action.to_sym)
        else
          # If no only, include it
          true
        end
      end
    end
  end
end
