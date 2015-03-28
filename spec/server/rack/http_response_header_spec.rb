require 'volt/server/rack/http_resonse_header'

describe Volt::HttpResponseHeader do

  it "it should headerize the keys" do
    header = Volt::HttpResponseHeader.new
    header[:content_type] = 'test'
    expect(header['Content-Type']).to eq('test')
    expect(header[:content_type]).to eq('test')
  end

  it "should delete keys" do
    header = Volt::HttpResponseHeader.new
    header[:content_type] = 'test'
    expect(header.delete(:content_type)).to eq('test')
    expect(header.size).to eq 0
  end

  it "should merge other plain hashes and headerize their keys" do
    header = Volt::HttpResponseHeader.new
    header[:content_type] = 'test'

    hash = Hash.new
    hash[:transfer_encoding] = 'encoding'

    expect(header.merge(hash)).to be_kind_of(Volt::HttpResponseHeader)
    expect(header.merge(hash)['Transfer-Encoding']).to eq('encoding')

    header.merge!(hash)
    expect(header['Transfer-Encoding']).to eq('encoding')
  end

end
