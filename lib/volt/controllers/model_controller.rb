require 'volt/reactive/reactive_accessors'
require 'volt/controllers/actions'

module Volt
  class ModelController
    include ReactiveAccessors
    include Actions

    reactive_accessor :current_model
    reactive_accessor :last_promise

    # The section is assigned a reference to a "DomSection" which has
    # the dom for the controllers view.
    attr_accessor :section

    # Setup before_action and after_action
    setup_action_helpers_in_class(:before, :after)

    # Container returns the node that is parent to all nodes in the section.
    def container
      section.container_node
    end

    def dom_nodes
      section.range
    end

    # yield_html renders the content passed into a tag as a string.  You can ```.watch!```
    # ```yield_html``` and it will be run again when anything in the template changes.
    def yield_html
      if (template_path = attrs.content_template_path)
        # TODO: Don't use $page global
        @yield_renderer ||= StringTemplateRender.new($page, self, template_path)
        @yield_renderer.html
      else
        # no template, empty string
        ''
      end
    end

    def self.model(val)
      @default_model = val
    end

    # Sets the current model on this controller
    def model=(val)
      if val.is_a?(Promise)
        # Resolve the promise before setting
        self.last_promise = val

        val.then do |result|
          # Only assign if nothing else has been assigned since we started the resolve
          self.model = result if self.last_promise == val
        end.fail do |err|
          Volt.logger.error("Unable to resolve promise assigned to model on #{inspect}")
        end

        return
      end

      # Clear
      self.last_promise = nil

      # Start with a nil reactive value.
      self.current_model ||= Model.new

      if Symbol === val || String === val
        collections = [:page, :store, :params, :controller]
        if collections.include?(val.to_sym)
          self.current_model = send(val)
        else
          fail "#{val} is not the name of a valid model, choose from: #{collections.join(', ')}"
        end
      else
        self.current_model = val
      end
    end

    def model
      model = self.current_model

      # If the model is a proc, call it now
      if model && model.is_a?(Proc)
        model = model.call
      end

      model
    end

    def self.new(*args, &block)
      inst = allocate

      inst.model = @default_model if @default_model

      # In MRI initialize is private for some reason, so call it with send
      inst.send(:initialize, *args, &block)

      inst
    end

    attr_accessor :attrs

    def initialize(*args)
      if args[0]
        # Assign the first passed in argument to attrs
        self.attrs = args[0]

        # If a model attribute is passed in, we assign it directly
        if attrs.respond_to?(:model)
          self.model = attrs.locals[:model]
        end
      end
    end

    # Change the url params, similar to redirecting to a new url
    def go(url)
      # We might be in the rendering loop, so wait until the next tick before
      # we change the url
      Timers.next_tick do
        self.url.parse(url)
      end
    end

    def page
      $page.page
    end

    def store
      $page.store
    end

    def flash
      $page.flash
    end

    def params
      $page.params
    end

    def local_store
      $page.local_store
    end

    def cookies
      $page.cookies
    end

    def url
      $page.url
    end

    def channel
      $page.channel
    end

    def tasks
      $page.tasks
    end

    def controller
      @controller ||= Model.new
    end

    def url_for(params)
      $page.url.url_for(params)
    end

    def url_with(params)
      $page.url.url_with(params)
    end

    # loaded? is a quick way to see if the model for the controller is loaded
    # yet.  If the model is there, it asks the model if its loaded.  If the model
    # was set to a promise, it waits for the promise to resolve.
    def loaded?
      if model.respond_to?(:loaded?)
        # There is a model and it is loaded
        return model.loaded?
      elsif last_promise || model.is_a?(Promise)
        # The model is a promise or is resolving
        return false
      else
        # Otherwise, its loaded
        return true
      end
    end

    def require_login
      unless Volt.current_user_id
        go '/login'

        stop_chain
      end
    end

    # Check if this controller responds_to method, or the model
    def respond_to?(method_name)
      super || begin
        model = self.model

        model.respond_to?(method_name) if model
      end
    end

    def method_missing(method_name, *args, &block)
      model = self.model

      if model
        model.send(method_name, *args, &block)
      else
        super
      end
    end
  end
end
