module Volt
  class SourceMapServer
    def initialize(sprockets)
      @sprockets = sprockets
    end

    attr_reader :sprockets

    attr_writer :prefix

    def prefix
      @prefix ||= '/__opal_source_maps__'
    end

    def inspect
      "#<#{self.class}:#{object_id}>"
    end

    def call(env)
      path_info = env['PATH_INFO']

      if path_info =~ /\.js\.map$/
        path  = env['PATH_INFO'].gsub(/^\/|\.js\.map$/, '')
        asset = sprockets[path]
        return [404, {}, []] if asset.nil?

        return [200, { 'Content-Type' => 'text/json' }, [$OPAL_SOURCE_MAPS[asset.pathname].to_s]]
      else
        return [200, { 'Content-Type' => 'text/text' }, [File.read(sprockets.resolve(path_info))]]
      end
    end
  end
end
