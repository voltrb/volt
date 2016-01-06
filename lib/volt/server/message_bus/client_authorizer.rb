# Authorizer class for authorizing message bus requests from the client
# This class is used in message_bus_tasks to check if publishing or subscribing to a given channel is
# allowed or not. With the help of this class, you can easily add your own authorization layer, which
# is applied to certain channels or modes. To do this, just create an instance of this class, for example
# in an initializer:
# Volt::MessageBus::ClientAuthorizer.new(:mode, 'channel1', 'channel2', ...) (see #initialize for param info)
# Next, you can add rules to the authorizer which are evaluated on subscribing / publishing to a channel of
# the MessageBus from a client. To do this, call 'allow_if' with a block:
# authorizer.allow_if do |task_context|
#   ...
#   break true
# end
# All authorization computations are executed in a task context (MessageBusTask), you get an instance of this
# task as a parameter, if you need it. To allow an action, your block has to return true, if it returns anything
# else subscribing/publishing is not allowed.
# You can add multiple blocks/allow_ifs to one authorizer, all of these blocks have to evaluate to true to proceed
# You can also add multiple authorizers to a channel, all associated authorizers have to evaluate to true to proceed
# This class supports method chaining, so you can do:
# Volt::MessageBus::ClientAuthorizer.new(:publish, 'my-channel').allow_if{|t| ... }.allow_if{...}
#
# If there is no authorizer found for a request, e. g. if you have only defined an authorizer for :publish, not for
# :subscribe, the action is denied.
#
#
# ClientAuthorizer also supports the use of namespaces. If your channel contains a ':', the first part of the
# channel name is interpreted as the namespace. On an authorization request, this class then looks for a namespace
# defining rule, too. In addition to channel rule (if any), the namespace rule is evaluated and has to return true, too.
# With the help of this, you can create a general authorizer for a class of channels (maybe for a volt component?) and
# specific, additional authorizers for some of the channels in this namespace. Or alternativly, you could restrict
# access to all channels with a namespace like 'chat:', and afterwards add use channels with the prefix 'chat:'
# dynamically, without the need of adding additional authorizers.
# All volt internals have the namespace 'volt:', so be careful on subscribing / publishing to these channels.
# We highly encourage you to use namespaces.
# Nesting of namespaces ('namespace1:namespace2:channel1') is currently unsupported
# To define an authorizer, which should apply to a namespace, use 'namespace:*' as channel name, for example:
# Volt::MessageBus::ClientAuthorizer.new(:subscribe, 'chat:*').make_public!
# Volt::MessageBus::ClientAuthorizer.new(:publish, 'chat:*').allow_if{.. check authentication? ..}
# Now you can use channels like 'chat:messages', 'chat:signals', etc which would all include the above two rules.
#
# Per default, there is already a 'public' namespace (see end of this file), which enables everyone to
# publish/subscribe to all channels in this namespace. If you want to disable this behaviour, use:
# Volt::MessageBus::ClientAuthorizer.new(:publish_and_subscribe, 'public:*').make_private!

module Volt
  module MessageBus
    class ClientAuthorizer
      attr_accessor :allow_if
      attr_reader :channels

      # Creates a new authorizer instance and adds it to the collection of checkable authorizers.
      # apply_on must be one of :publish, :subscribe or :publish_and_subscribe and defines when this
      # authorizer is triggered, on publishing or subscribing or both.
      # All other given parameters are evaluated as channels this authorizer shall include rules for.
      # An authorizer is only triggered if it contains the requested channel and if apply_on fits to the requested mode
      def initialize(apply_on, *channels)
        raise 'apply_on must be :publish, :subscribe or :publish_and_subscribe' unless [:publish, :subscribe, :publish_and_subscribe].include? apply_on

        raise 'a minimum of one channel is needed' if channels.nil? || channels.size == 0

        @apply_on_publishing = @apply_on_subscribing = false
        apply_on_publishing if apply_on == :publish
        apply_on_subscribing if apply_on == :subscribe
        apply_on_publishing_and_subscribing if apply_on == :publish_and_subscribe

        self.channels = channels

        reinitialize_rules!
      end

      # Reinitializes all rules, setting @allow_if to []
      def reinitialize_rules!
        @allow_if = []
        return self
      end

      # Makes channel/apply_on combination accessible for everyone
      def make_public!
        reinitialize_rules!
        allow_if do
          true
        end
        return self
      end

      # Makes channel/apply_on combination accessible for noone
      def make_private!
        reinitialize_rules!
        allow_if do
          false
        end
        return self
      end

      # Checks if for the given context (which should be a task instance / instance of MessageBusTasks)
      # all contained rules return true
      def authorized?(task_context)
        # If there is no rule, action is unauthorized
        return false if @allow_if.empty?

        # else, check all rules and return false if any of them did not return true
        # do not check all rules if unnecessary
        @allow_if.each do |rule|
          return false if rule.call(task_context) != true
        end

        true
      end

      # Adds another rule to this authorizer
      # Just pass a block to this method, this block will be called with
      # the task_context as a parameter on an authorization request
      # Your block has to return true if it should authorize the action,
      # all other return values are interpreted as false
      def allow_if(&block)
        @allow_if << block
        return self
      end

      def channels=(channels)
        self.class.remove_from channels, self
        @channels = channels
        self.class.add_to channels, self
      end

      # Applies authorizer to publishing requests
      def apply_on_publishing
        @apply_on_publishing = true
        return self
      end

      # Applies authorizer to subscribing requests
      def apply_on_subscribing
        @apply_on_subscribing = true
        return self
      end

      # Unapplies authorizer to publishing requests
      def unapply_on_publishing
        @apply_on_publishing = false
        return self
      end

      # Unapplies authorizer to publishing requests
      def unapply_on_subscribing
        @apply_on_subscribing = false
        return self
      end

      def apply_on_publishing?
        @apply_on_publishing
      end

      def apply_on_subscribing?
        @apply_on_subscribing
      end

      # Applies authorizer to publishing and subscribing requests
      def apply_on_publishing_and_subscribing
        apply_on_subscribing
        apply_on_publishing
        return self
      end

      # Unapplies authorizer to publishing and subscribing requests (=> disables it)
      def unapply_publishing_and_subscribing
        unapply_on_subscribing
        unapply_on_publishing
        return self
      end

      # Adds an authorizer to the global authorizer collection by building a hasmap
      # based on the authorizer's channels
      def self.add_to(channels, authorizer)
        @authorizers ||= {}
        channels.each do |channel|
          @authorizers[channel] ||= []
          @authorizers[channel] << authorizer
        end
      end

      # Opposite of #add_to: removes authorizer from a given list of channels in the
      # authorizer collection
      def self.remove_from(channels, authorizer)
        channels.each do |channel|
          if @authorizers && @authorizers[channel]
            @authorizers[channel].delete authorizer
          end
        end
      end

      # Returns all authorizers (including namespace authorizers) which are associated to
      # the given channel
      def self.find_authorizers(channel)
        return [] if @authorizers.nil?
        result = []

        # 1) add exact rules for channel name
        result = result + @authorizers[channel] if @authorizers[channel]

        # 2) look for namespace rules
        if channel.include?(":")
          namespace_channel = channel.split(":").first + ":*"
          result = result + @authorizers[namespace_channel] if @authorizers[namespace_channel]
        end

        result
      end

      # Filters a given list of authorizers, returns filtered list with authorizers which do all
      # apply on the given mode (:publish or :subscribe)
      def self.filter_appliance(authorizers, mode)
        raise 'mode must be :publish or :subscribe' unless [:publish, :subscribe].include? mode

        filter_method = (mode == :publish) ? :apply_on_publishing? : :apply_on_subscribing?
        authorizers.select{|authorizer| authorizer.send filter_method}
      end

      # Checks if :publish or :subscribe to a given channel is allowed by evaluating all authorizers
      # Needs task_context, which is in anstance of MessageBusTasks
      # This method is used in MessageBusTasks to check the client's rights to publish/subscribe to a channel
      def self.authorized?(task_context, mode, channel)
        raise 'mode must be :publish or :subscribe' unless [:publish, :subscribe].include? mode

        # Find all fitting authorizers
        authorizers = find_authorizers channel
        authorizers = filter_appliance authorizers, mode

        # If there is no authorizer for this mode, action is unauthorized
        # this means, per default, all actions are unauthorized
        return false if authorizers.empty?

        # Else, loop through all authorizers, return false if any of them
        # did not return true
        authorizers.each do |authorizer|
          return false if authorizer.authorized?(task_context) != true
        end

        # If all checks passed, authorize action
        true
      end
    end
  end
end


# Default rule: Make everything public for all channel names starting with 'public:'
Volt::MessageBus::ClientAuthorizer.new(:publish_and_subscribe,
  'public:*').make_public!