require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe "SimpleJsonApiController" do
    include Rack::Test::Methods

    let(:app) { Volt.current_app.middleware }

    def json_response
      JSON.parse(last_response.body, symbolize_names: true)
    end
    
    def headers
      { 'CONTENT_TYPE' => 'application/json'  }
    end

    before(:each) do
      store.issues.reverse.each do |issue|
        issue.destroy
      end
    end

    it 'should return a list of resources as json' do
      store.issues << Issue.new(name: 'test')
      get '/api/issues'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to eq('application/json')
      expect(json_response).to eq(issues: store.issues)
    end

    it 'should returns a single resource as json' do
      store.issues << Issue.new(name: 'first')
      issue = store.issues.create(name: 'test').sync
      get '/api/issues/' + issue.id
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to eq('application/json')
      expect(json_response).to eq(issue: issue.to_h)
    end

    it 'should respond with 404 if the resource can not be found' do
      get '/api/issues/0'
      expect(last_response.status).to eq(404)
    end

    it 'destroys a resource' do
      first = store.issues.create(name: 'first').sync
      issue = store.issues.create(name: 'second').sync
      delete '/api/issues/' + issue.id
      expect(last_response.status).to eq(204)
      expect(store.issues.to_a.sync).to eq([first.to_h])
    end

    it 'creates a resource' do
      payload = JSON.dump({ issue: {name: 'a issue' } })
      expect(store.issues.count.sync).to eq(0)
      post '/api/issues', payload, headers
      puts last_response.body
      expect(last_response.status).to eq(201)
      expect(store.issues.count.sync).to eq(1)
      issue = store.issues.first.sync
      expect(last_response.body).to be_empty
      expect(issue.name).to eq('a issue')
      # TODO http_controllers should be able to get routes via params
      #expect(last_response.header['Location']).to match("/api/issues/" + issue.id)
    end

    it 'updates a resource' do
      issue = store.issues.create(name: 'test').sync
      payload = JSON.dump({ issue: {name: 'new name' } })
      put '/api/issues/' + issue.id, payload, headers
      puts last_response.body
      expect(last_response.status).to eq(204)
      issue = store.issues.first.sync
      expect(issue.name).to eq 'new name'
    end
  end
end
