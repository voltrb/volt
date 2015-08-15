require 'volt/utils/ejson'

module Volt
  class Browser
    attr_reader :events

    def initialize(volt_app)
      @volt_app = volt_app
      # Run the code to setup the page

      @url_tracker = UrlTracker.new(@volt_app)

      @events = DocumentEvents.new

      # Initialize tasks so we can get the reload message
      @volt_app.tasks if Volt.env.development?

      if RUBY_PLATFORM == 'opal'
        if Volt.in_browser?
          # Setup click handler for links
          `
            $(document).on('click', 'a', function(event) {
              var browser = #{Volt.current_app.browser};
              return browser.$link_clicked($(this).attr('href'), event);
            });
          `
        end
      end

      if Volt.in_browser?
        @volt_app.channel.on('reconnected') do
          @volt_app.page._reconnected = true

          `setTimeout(function() {`
            @volt_app._reconnected = false
          `}, 2000);`
        end
      end
    end

    def link_clicked(url = '', event = nil)
      target = nil
      `target = $(event.target).attr('target');`
      `if (!target) {`
        `target = #{nil};`
      `}`

      if target.present? && target != '_self'
        # Don't handle if they are opening in a new window
        return true
      end

      # Skip when href == ''
      return false if url.blank?

      # Normalize url
      if @volt_app.url.parse(url)
        if event
          # Handled new url
          `event.stopPropagation();`
        end

        # Clear the flash
        @volt_app.flash.clear

        # return false to stop the event propigation
        return false
      end

      # Not stopping, process link normally
      true
    end

    # We provide a binding_name, so we can bind events on the document
    def binding_name
      'page'
    end

    def start
      # Setup to render template
      `$('body').html('<!-- $CONTENT --><!-- $/CONTENT -->');`

      load_stored_page

      # Do the initial url params parse
      @url_tracker.url_updated(true)

      main_controller = Main::MainController.new(@volt_app)

      # Setup main page template
      TemplateRenderer.new(@volt_app, DomTarget.new, main_controller, 'CONTENT', 'main/main/main/body')

      # Setup title reactive template
      @title_template = StringTemplateRenderer.new(@volt_app, main_controller, 'main/main/main/title')

      # Watch for changes to the title template
      proc do
        title = @title_template.html.gsub(/\n/, ' ')
        `document.title = title;`
      end.watch!
    end

    # When the page is reloaded from the backend, we store the page collection,
    # so we can reload the page in the exact same state.  Speeds up development.
    def load_stored_page
      if Volt.client?
        if `sessionStorage`
          page = Volt.current_app.page
          page_obj_str = nil

          `page_obj_str = sessionStorage.getItem('___page');`
          `if (page_obj_str) {`
          `sessionStorage.removeItem('___page');`

          EJSON.parse(page_obj_str).each_pair do |key, value|
            page.send(:"_#{key}=", value)
          end
          `}`
        end
      end
    rescue => e
      Volt.logger.error("Unable to restore: #{e.inspect}")
    end
  end
end