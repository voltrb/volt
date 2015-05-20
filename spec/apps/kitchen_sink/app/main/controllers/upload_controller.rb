module Main
  class UploadController < Volt::ModelController
    model :page

    def index
      # Nothing to setup here
    end

    def upload
      `form_data = new FormData();
       form_data.append("file", $('#file')[0].files[0]);
       $.ajax({
         url: '/simple_http/upload',
         data: form_data,
         processData: false,
         contentType: false,
         type: 'POST',
         success: function(data){
          $('#status').html("successfully uploaded");
        }
      });`
    end
  end
end
