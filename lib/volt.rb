class Volt
  def self.root
    @root ||= File.expand_path(Dir.pwd)
  end
  
  def self.server?
    !ENV['CLIENT']
  end
  
  def self.client?
    !!ENV['CLIENT']
  end
end