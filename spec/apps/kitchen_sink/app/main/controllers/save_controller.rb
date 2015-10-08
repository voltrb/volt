module Main
  class SaveController < Volt::ModelController
    def add_post
      store.posts.create(page._new_post.to_h).fail do |err|
        puts err.inspect
        flash._notices << err.inspect
      end
    end
  end
end