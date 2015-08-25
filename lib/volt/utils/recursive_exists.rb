module Volt
  module RecursiveExists
    def self.exists_here_or_up?(file)
      # Check for a gemfile here or up a directory
      pwd = Dir.pwd

      loop do
        if File.exists?("#{pwd}/#{file}")
          return true
        else
          pwd = pwd.gsub(/\/[^\/]+$/, '')
          return false if pwd == ''
        end
      end

      false
    end
  end
end