require 'volt/server/rack/http_response_renderer'

describe Volt::HttpResponseRenderer do

  let(:renderer) { Volt::HttpResponseRenderer.new }

  it "should render json" do
    hash = { a: "aa", bb: "bbb" }
    body, additional_headers = renderer.render json: hash
    expect(body).to eq(hash.to_json)
    expect(additional_headers[:content_type]).to eq('application/json')
  end

  it "should render plain text" do
    text = "just some text"
    body, additional_headers = renderer.render(plain: text)
    expect(body).to eq(text)
    expect(additional_headers[:content_type]).to eq('text/plain')
  end
end
