class Console
  def self.start
    require 'pry'

    $LOAD_PATH << 'lib'
    ENV['SERVER'] = 'true'

    require 'volt/extra_core/extra_core'
    require 'volt/models'
    require 'volt/models/params'
    require 'volt/server/template_parser'
    require 'volt'

    Pry.config.prompt_name = 'volt'

    # start a REPL session
    Pry.start
  end
end