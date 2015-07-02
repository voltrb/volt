# The Volt::Repos module provides access to each root collection (repo).

module Volt
  module Repos
    def url
      @url ||= URL.new
    end

    def params
      @params ||= @url.params
    end

    def page
      @page ||= PageRoot.new
    end

    def store
      @store ||= StoreRoot.new({}, persistor: Persistors::StoreFactory.new(tasks))
    end

    def flash
      @flash ||= begin
        check_for_client?('flash')
        FlashRoot.new({}, persistor: Persistors::Flash)
      end
    end

    def local_store
      @local_store ||= begin
        check_for_client?('local_store')
        LocalStoreRoot.new({}, persistor: Persistors::LocalStore)
      end
    end

    def cookies
      @cookies ||= begin
        check_for_client?('cookies')
        CookiesRoot.new({}, persistor: Persistors::Cookies)
      end
    end

    def check_for_client?(repo_name)
      unless Volt.client?
        fail "The #{repo_name} collection can only be accessed from the client side currently"
      end
    end
  end
end