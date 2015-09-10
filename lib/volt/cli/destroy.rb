class Destroy < Thor
  include Generators

  def initialize(*)
    super
    self.behavior = :revoke
  end
end
