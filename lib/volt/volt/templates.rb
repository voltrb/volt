# The Templates class holds all loaded templates.
module Volt
  class Templates
    # On the server, we can delay loading the views until they are actually requeted.  This
    # sets up an instance variable to call to load.
    attr_writer :template_loader

    def initialize
      @templates = {}
    end

    def [](key)
      templates[key]
    end

    def add_template(name, template, bindings)
      # First template gets priority.  The backend will load templates in order so
      # that local templates come in before gems (so they can be overridden).
      #
      # TODO: Currently this means we will send templates to the client that will
      # not get used because they are being overridden.  Need to detect that and
      # not send them.
      unless @templates[name]
        @templates[name] = { 'html' => template, 'bindings' => bindings }
      end
    end

    # Load the templates on first use if a loader was specified
    def templates
      if @template_loader
        # Load the templates
        @template_loader.call
        @template_loader = nil
      end

      @templates
    end
  end
end
