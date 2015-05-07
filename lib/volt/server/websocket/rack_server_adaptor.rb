begin
  require 'puma'
  RUNNING_SERVER = 'puma'
rescue LoadError => e
  begin
    require 'thin'
    RUNNING_SERVER = 'thin'
  rescue LoadError => e
    Volt.logger.error('Unable to find a compatible rack server, please make sure your Gemfile includes one of the following: thin or puma')
  end
end

module Volt
  class RackServerAdaptor
    def self.load
      Faye::WebSocket.load_adapter(RUNNING_SERVER)
    end
  end
end
