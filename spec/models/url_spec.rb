require 'spec_helper'
require 'volt/models/url'

describe Volt::URL do
  let(:uri) { 'http://voltframework.com:8888/path/1?query=val#fragment' }

  let(:fake_location) do
    double(
      'Location',
      host: 'voltframework.com',
      protocol: 'http:'
    )
  end

  before do
    allow(Location).to receive(:new).and_return fake_location
    subject.parse uri
  end

  subject { described_class.new fake_router }

  describe '#parse' do
    let(:fake_router) { double('Router', url_to_params: { foo: 'bar' }) }
    context 'with a valid url' do
      it 'returns "http" for scheme' do
        expect(subject.scheme).to eq 'http'
      end

      it 'returns "voltframework.com" for #host' do
        expect(subject.host).to eq 'voltframework.com'
      end

      it 'returns 8888 for #port' do
        expect(subject.port).to eq 8888
      end

      it 'returns "/path/1" for #path' do
        expect(subject.path).to eq '/path/1'
      end

      it 'returns "query=val" for #query' do
        expect(subject.query).to eq 'query=val'
      end

      it 'returns "fragment" for #fragment' do
        expect(subject.fragment).to eq 'fragment'
      end
    end
  end

  describe '#url_for' do
    let(:fake_router) do
      router = Volt::Routes.new

      router.define do
        client '/path/{{ id }}', view: 'blog/show'
      end
    end

    it 'regenerates the URL for the given params' do
      params = { view: 'blog/show', id: '1', query: 'val' }

      expect(subject.url_for params).to eq uri
    end
  end

  describe '#url_with' do
    let(:uri) { 'http://voltframework.com:8888/path/1?query=val&page=1#fragment' }
    let(:fake_router) do
      router = Volt::Routes.new

      router.define do
        client '/path/{{ id }}', view: 'blog/show'
      end
    end

    it 'regenerates the URL and merges the given params' do
      params = { page: 1 }
      expect(subject.url_with params).to eq uri
    end
  end
end
