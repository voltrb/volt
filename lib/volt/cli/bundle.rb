module Volt
  module Bundle
    # Run bundle from inside of cli, borrowed from rails:
    # https://github.com/rails/rails/blob/21f7bcbaa7709ed072bb2e1273d25c09eeaa26d9/railties/lib/rails/generators/app_base.rb
    def bundle_command(command)
      say_status :run, "bundle #{command}"

      # We are going to shell out rather than invoking Bundler::CLI.new(command)
      # because `volt new` loads the Thor gem and on the other hand bundler uses
      # its own vendored Thor, which could be a different version. Running both
      # things in the same process is a recipe for a night with paracetamol.
      #
      # We unset temporary bundler variables to load proper bundler and Gemfile.
      #
      # Thanks to James Tucker for the Gem tricks involved in this call.
      _bundle_command = Gem.bin_path('bundler', 'bundle')

      require 'bundler'
      Bundler.with_clean_env do
        full_command = %Q["#{Gem.ruby}" "#{_bundle_command}" #{command}]
        if options[:quiet]
          system(full_command, out: File::NULL)
        else
          system(full_command)
        end
      end
    end
  end
end