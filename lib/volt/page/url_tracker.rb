module Volt
  # The URLTracker is responsible for updating the url when
  # a param changes, or updating the url model/params when
  # the browser url changes.
  class UrlTracker
    def initialize(page)
      @page = page

      if Volt.client?
        that = self

        # Setup popstate on the dom ready event.  Prevents an extra
        # popstate trigger
        `
          window.addEventListener("popstate", function(e) {
            that.$url_updated();
            return true;
          });
        `
      end
    end

    def url_updated(first_call = false)
      @page.url.parse(`document.location.href`)
      @page.url.update! unless first_call
    end
  end
end
