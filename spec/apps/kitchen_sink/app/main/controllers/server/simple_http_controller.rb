module Main
  class SimpleHttpController < Volt::HttpController
    def index
      render text: 'this is just some text'
    end

    def show
      render text: "You had me at #{store._simple_http_tests.first._name.sync}"
    end

    def upload
      uploaded = params._file._tempfile
      File.open('tmp/uploaded_file', 'wb') { |f| f.write(uploaded.read) }
      render text: 'Thanks for uploading'
    end
  end
end
