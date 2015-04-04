class SimpleHttpController < Volt::HttpController

  def index
    render plain: "this is just some text"
  end

  def show
    render plain: "You had me at #{store._simple_http_tests.first._name}"
  end

  def upload
    uploaded = params[:file][:tempfile]
    File.open('tmp/uploaded_file', "wb") { |f| f.write(uploaded.read) }
    render plain: "Thanks for uploading"
  end

end