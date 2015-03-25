unless RUBY_PLATFORM == 'opal'
  require 'spec_helper'
  require 'volt/server/rack/quiet_common_logger'

  describe QuietCommonLogger do
    subject { QuietCommonLogger.new(nil, nil) }
    let(:fake_class) { Class.new }
    let(:app) { double 'App', call: [:status, :header, :body] }

    before(:each) do
      allow(app).to receive(:call)
      subject.instance_variable_set :@app, app
    end

    describe '#call' do
      before(:each) do
        header_hash = stub_const('Rack::Utils::HeaderHash', fake_class)
        allow(header_hash).to receive(:new)

        proxy = stub_const('Rack::BodyProxy', fake_class)
        allow(proxy).to receive(:new)

        allow(subject).to receive(:log)
      end

      describe 'when request path has no file extension and request run over web socket' do
        let(:env) { {'REQUEST_PATH' => '/file'} }

        it "calls 'log' method" do
          expect(subject).to receive(:log)
          subject.call env
        end
      end

      describe 'when request path has file extension' do
        let(:env) { {'REQUEST_PATH' => '/file.ext'} }

        it "doesn't call 'log' method" do
          expect(subject).not_to receive(:log)
          subject.call env
        end
      end

      describe 'when request run over web socket' do
        let(:env) { {'REQUEST_PATH' => '/channel'} }

        it "doesn't call 'log' method" do
          expect(subject).not_to receive(:log)
          subject.call env
        end
      end
    end
  end
end
