if RUBY_PLATFORM != 'opal'
  require 'spec_helper'

  describe Rack::HttpContentTypes do
    include Rack::Test::Methods

    let(:app) { Volt.current_app.middleware }

    before do
      Volt.setup do |config|
        config.http_content_types = {
          parsers: {
            'application/roll' => proc { |body| {'rick_says' => 'never gonna give you up'}}
          }
        }
      end
    end

    it "allows you to setup parsers for content types" do
      middleware = Rack::HttpContentTypes.new Volt, :parsers => { 'foo' => 'bar' } 
      expect(middleware.parsers['foo']).to eq('bar')
    end

    it "allows you to setup error handlers" do
      middleware = Rack::HttpContentTypes.new Volt, :handlers => { 'foo' => 'bar' } 
      expect(middleware.handlers['foo']).to eq('bar')
    end

    it "parses params from Content-Type: application/json" do
      payload = JSON.dump(:a => 1)
      post '/simple_http', payload, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response).to be_ok
      expect(last_response.body).to match(/a: 1/)
    end

    it "does not handle params from unknown Content-type" do
      payload = JSON.dump(:a => 1)
      post '/simple_http', payload, { 'CONTENT_TYPE' => 'application/unknown' }
      expect(last_response).to be_ok
      expect(last_response.body).to_not match(/a: 1/)
    end

    it "matches Content-Type by regex" do
      payload = JSON.dump(:a => 1)
      post '/simple_http', payload, { 'CONTENT_TYPE' => 'application/vnd.foo+json' }
      expect(last_response).to be_ok
      expect(last_response.body).to match(/a: 1/)
    end

    it "handles custom content types" do
      #see spec/apps/kitchen_sink/config/app.rb
      payload = JSON.dump(:a => 1)
      post '/simple_http', payload, { 'CONTENT_TYPE' => 'application/roll' }
      expect(last_response).to be_ok
      expect(last_response.body).to match(/never gonna give you up/)
    end

    it "handles custom json parser" do
      Volt.setup do |config|
        config.http_content_types = {
          parsers:{
            'application/json' => proc { |body| {'rick_says' => 'never gonna let you down'} }
          }
        }
      end
      payload = JSON.dump(:a => 1)
      post '/simple_http', payload, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response).to be_ok
      expect(last_response.body).to match(/never gonna let you down/)
    end
  end
end
