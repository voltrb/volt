module Volt
  class ComponentTemplates
    module Preprocessors #:nodoc:
      # Setup default handler on extend
      def self.extended(base)
        base.register_template_handler :html, BasicHandler.new
        base.register_template_handler :email, BasicHandler.new
      end

      @@template_handlers = {}

      def self.extensions
        @@template_handlers.keys
      end

      # Register an object that knows how to handle template files with the given
      # extensions. This can be used to implement new template types.
      # The handler must respond to +:call+, which will be passed the template
      # and should return the rendered template as a String.
      def register_template_handler(extension, handler)
        @@template_handlers[extension.to_sym] = handler
      end

      def registered_template_handler(extension)
        extension && @@template_handlers[extension.to_sym]
      end

      def handler_for_extension(extension)
        registered_template_handler(extension)
      end
    end
  end
end