require 'spec_helper'

describe Volt::App do
  [:cookies, :flash, :local_store].each do |repo|
    it "should raise an error when accessing #{repo} from the server" do
      expect do
        volt_app.send(repo)
      end.to raise_error("The #{repo} collection can only be accessed from the client side currently")
    end
  end
end