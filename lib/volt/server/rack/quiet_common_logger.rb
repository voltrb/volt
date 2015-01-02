require 'rack'
class QuietCommonLogger < Rack::CommonLogger
  include Rack

  @@ignore_extensions = %w(png jpg jpeg ico gif woff tff svg eot css js)

  def call(env)
    path = env['REQUEST_PATH']
    began_at = Time.now
    status, header, body = @app.call(env)
    header = Utils::HeaderHash.new(header)
    base = ::File.basename(path)
    if base.index('.')
      ext = base.split('.').last
    else
      ext = nil
    end

    body = BodyProxy.new(body) do
      # Don't log on ignored extensions
      unless @@ignore_extensions.include?(ext)
        log(env, status, header, began_at)
      end
    end

    # Because of web sockets, the initial request doesn't finish, so we
    # can just trigger it now.
    if !ext && !path.start_with?('/channel')
      log(env, status, header, began_at)
    end

    [status, header, body]
  end
end
