# The URLTracker is responsible for updating the url when
# a param changes, or updating the url model/params when
# the browser url changes.
class UrlTracker
  def initialize(page)
    @page = page

    if Volt.client?
      # TODORW:
      # page.params.on('child_changed') do
      #   @page.url.update!
      # end

      that = self

      # Setup popstate on the dom ready event.  Prevents an extra
      # popstate trigger
      %x{
        var first = true;
        window.addEventListener("popstate", function(e) {
          if (first === false) {
            that.$url_updated();
          }

          first = false;

          return true;
        });
      }
    end
  end

  def url_updated(first_call=false)
    @page.url.parse(`document.location.href`)
    @page.url.update! unless first_call
  end
end
