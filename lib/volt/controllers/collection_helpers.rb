# Collection helpers provide methods to access methods of page directly.
# @page is expected to be defined and a Volt::Page
module Volt
  module CollectionHelpers
    def url
      Volt.current_app.url
    end

    def url_for(params)
      Volt.current_app.url.url_for(params)
    end

    def url_with(params)
      Volt.current_app.url.url_with(params)
    end

    def store
      Volt.current_app.store
    end

    def page
      Volt.current_app.page
    end

    def flash
      Volt.current_app.flash
    end

    def params
      Volt.current_app.params
    end

    def local_store
      Volt.current_app.local_store
    end

    def cookies
      Volt.current_app.cookies
    end

    def channel
      Volt.current_app.channel
    end

    def tasks
      Volt.current_app.tasks
    end
  end
end