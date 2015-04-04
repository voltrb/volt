if RUBY_PLATFORM != 'opal'
  require 'volt/server/rack/http_request'

  describe Volt::HttpRequest do
    def env_for(url, opts = {})
      Rack::MockRequest.env_for(url, opts)
    end

    it 'should report the correct format' do
      env = env_for('http://example.com/test.html',
                    'CONTENT_TYPE' => 'text/plain;charset=utf-8')
      request = Volt::HttpRequest.new(env)
      expect(request.format).to eq('html')

      env = env_for('http://example.com/test',
                    'CONTENT_TYPE' => 'text/plain;charset=utf-8')
      request = Volt::HttpRequest.new(env)
      expect(request.format).to eq('text/plain')
    end

    it 'should remove the format from the path' do
      env = env_for('http://example.com/test.html',
                    'CONTENT_TYPE' => 'text/plain;charset=utf-8')
      request = Volt::HttpRequest.new(env)
      expect(request.path).to eq('/test')
    end

    it 'should return the correct http method' do
      env = env_for('http://example.com/test.html', method: 'GET')
      request = Volt::HttpRequest.new(env)
      expect(request.method).to eq(:get)

      env = env_for('http://example.com/test.html',
                    method: 'POST', params: { _method: 'put' })
      request = Volt::HttpRequest.new(env)
      expect(request.method).to eq(:put)
    end

    it 'should return the params with symbolized keys' do
      env = env_for(
        'http://example.com/test.html',
        method: 'POST',
        params: { 'some' => 'params', 'as' => 'strings', and: 'symbols' })
      request = Volt::HttpRequest.new(env)

      wanted = { some: 'params', as: 'strings', and: 'symbols' }
      expect(request.params).to eq(wanted)
    end
  end
end
