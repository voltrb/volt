require 'bundler/setup'
require 'thor'

class CLI < Thor
  include Thor::Actions
  
  desc "new PROJECT_NAME", "generates a new project."
  def new(name)
    directory("project", name)
    
    say "Bundling Gems...."
    `cd #{name} ; bundle`
  end
  
  desc "console", "run the console on the project in the current directory"
  def console
    require 'volt/console'
    Console.start
  end

  desc "server", "run the server on the project in the current directory"
  def server
    require 'thin'

    ENV['SERVER'] = 'true'
    Thin::Runner.new(['start']).run!
  end
  
  desc "gem GEM", "Creates a skeleton for creating a rubygem"
  method_option :bin, :type => :boolean, :default => false, :aliases => '-b', :banner => "Generate a binary for your library."
  method_option :test, :type => :string, :lazy_default => 'rspec', :aliases => '-t', :banner => "Generate a test directory for your library: 'rspec' is the default, but 'minitest' is also supported."
  method_option :edit, :type => :string, :aliases => "-e",
                :lazy_default => [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find{|e| !e.nil? && !e.empty? },
                :required => false, :banner => "/path/to/your/editor",
                :desc => "Open generated gemspec in the specified editor (defaults to $EDITOR or $BUNDLER_EDITOR)"
  def gem(name)
    name = "volt-" + name.chomp("/") # remove trailing slash if present
    namespaced_path = name.tr('-', '/')
    target = File.join(Dir.pwd, name)
    constant_name = name.split('_').map{|p| p[0..0].upcase + p[1..-1] }.join
    constant_name = constant_name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/
    constant_array = constant_name.split('::')
    git_user_name = `git config user.name`.chomp
    git_user_email = `git config user.email`.chomp
    volt_version_base = File.read(File.join(File.dirname(__FILE__), '../../VERSION')).split('.').tap {|v| v[v.size-1] = 0 }.join('.')
    
    opts = {
      :name            => name,
      :namespaced_path => namespaced_path,
      :constant_name   => constant_name,
      :constant_array  => constant_array,
      :author          => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
      :email           => git_user_email.empty? ? "TODO: Write your email address" : git_user_email,
      :test            => options[:test],
      :volt_version_base => volt_version_base
    }
    gemspec_dest = File.join(target, "#{name}.gemspec")
    template(File.join("newgem/Gemfile.tt"),               File.join(target, "Gemfile"),                             opts)
    template(File.join("newgem/Rakefile.tt"),              File.join(target, "Rakefile"),                            opts)
    template(File.join("newgem/LICENSE.txt.tt"),           File.join(target, "LICENSE.txt"),                         opts)
    template(File.join("newgem/README.md.tt"),             File.join(target, "README.md"),                           opts)
    template(File.join("newgem/gitignore.tt"),             File.join(target, ".gitignore"),                          opts)
    template(File.join("newgem/newgem.gemspec.tt"),        gemspec_dest,                                             opts)
    template(File.join("newgem/lib/newgem.rb.tt"),         File.join(target, "lib/#{namespaced_path}.rb"),           opts)
    template(File.join("newgem/lib/newgem/version.rb.tt"), File.join(target, "lib/#{namespaced_path}/version.rb"),   opts)
    if options[:bin]
      template(File.join("newgem/bin/newgem.tt"),          File.join(target, 'bin', name),                           opts)
    end
    case options[:test]
    when 'rspec'
      template(File.join("newgem/rspec.tt"),               File.join(target, ".rspec"),                              opts)
      template(File.join("newgem/spec/spec_helper.rb.tt"), File.join(target, "spec/spec_helper.rb"),                 opts)
      template(File.join("newgem/spec/newgem_spec.rb.tt"), File.join(target, "spec/#{namespaced_path}_spec.rb"),     opts)
    when 'minitest'
      template(File.join("newgem/test/minitest_helper.rb.tt"), File.join(target, "test/minitest_helper.rb"),         opts)
      template(File.join("newgem/test/test_newgem.rb.tt"),     File.join(target, "test/test_#{namespaced_path}.rb"), opts)
    end
    if options[:test]
      template(File.join("newgem/.travis.yml.tt"),         File.join(target, ".travis.yml"),            opts)
    end
    say "Initializing git repo in #{target}"
    Dir.chdir(target) { `git init`; `git add .` }

    if options[:edit]
      run("#{options["edit"]} \"#{gemspec_dest}\"")  # Open gemspec in editor
    end
  end
  
  
  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), '../../templates'))
  end
end

CLI.start(ARGV)