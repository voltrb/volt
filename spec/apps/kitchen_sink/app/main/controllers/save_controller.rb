module Main
  class SaveController < Volt::ModelController
    def add_post
      puts "Create with: #{page._new_post.to_h.inspect}"
      store.posts.create(page._new_post.to_h).fail do |err|
        flash._notices << "Error as class: " + err.class.to_s
      end
    end
  end
end