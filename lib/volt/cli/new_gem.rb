require 'net/http'
require 'uri'
require 'fileutils'

# Creates a new "volt" gem, which can be used to easily repackage
# components.
class NewGem
  def initialize(thor, name, options)
    @thor = thor
    @component_name = name.chomp('/')
    @name = 'volt-' + @component_name # remove trailing slash if present
    @shell = Thor::Base.shell.new

    if gem_is_available?
      @thor.say("#{@name} is available!  Making gem files.", :green)
    else
      @thor.say("There is already a gem named #{@name}.  Please choose a different name.", :red)
      return
    end

    @options = options
    @namespaced_path = @name.tr('-', '/')
    @opts = gem_options
    @target = File.join(Dir.pwd, @name)

    copy_files
    copy_options

    # Create a sample project inside of the specs folder
    Dir.chdir(@target + '/spec') do
      @thor.say 'Generating dummy project for integration specs', :green
      cli = Volt::CLI.new
      cli.shell.mute do
        cli.new_project('dummy', true, true)
      end

      # Remove gemfile
      FileUtils.rm('dummy/Gemfile')

      # Remove spec directory inside of dummy app
      FileUtils.rm_rf('dummy/spec')
    end

    puts "Initializing git repo in #{@target}"
    Dir.chdir(@target) { `git init`; `git add .` }

  end

  # Check with the rubygems api to see if this gem name is available.
  def gem_is_available?
    @thor.say("Check if #{@name} is available as a gem name.", :yellow)
    uri = URI.parse("https://rubygems.org/api/v1/gems/#{@name}.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    return response.code == '404'
  rescue SocketError => e
    # rubygems is down, skip check
    return true
  end

  def copy_files
    @thor.directory('newgem/app/newgem', File.join("#{@target}", "app/#{@component_name}"), @opts)
    copy('newgem/Gemfile.tt', 'Gemfile')
    copy('newgem/Rakefile.tt', 'Rakefile')
    copy('newgem/README.md.tt', 'README.md')
    copy('newgem/gitignore.tt', '.gitignore')
    copy('newgem/newgem.gemspec.tt', "#{@name}.gemspec")
    copy('newgem/lib/newgem.rb.tt', "lib/#{@namespaced_path}.rb")
    FileUtils.mkdir_p(File.join(@target, "lib/#{@namespaced_path}"))
    copy('newgem/lib/newgem/version.rb.tt', "lib/#{@namespaced_path}/version.rb")
  end

  def copy_options
    if @options[:coc] or yes?("\nDo you want to include a code of conduct in this gem?\n\n\
Codes of conduct can increase contributions to your project by contributors who \
prefer collaborative, safe spaces. You can read more about the code of conduct at \
contributor-covenant.org. Having a code of conduct means agreeing to the responsibility \
of enforcing it, so be sure that you are prepared to do that. For suggestions about \
how to enforce codes of conduct, see bit.ly/coc-enforcement.\n\ny/(n):")

      copy('newgem/CODE_OF_CONDUCT.md.tt', 'CODE_OF_CONDUCT.md')
    end

    if @options[:mit] or yes?("\nDo you want to license your code permissively under the MIT license?\n\n\
This means that any other developer or company will be legally allowed to use your code \
for free as long as they admit you created it. You can read more about the MIT license \
at choosealicense.com/licenses/mit.\n\ny/(n):")

      copy('newgem/LICENSE.txt.tt', 'LICENSE.txt')
    end

    copy('newgem/bin/newgem.tt', "bin/#{@name}") if @options[:bin]
    copy('newgem/rspec.tt', '.rspec')
    copy('newgem/spec/spec_helper.rb.tt', 'spec/spec_helper.rb')
    copy('newgem/spec/newgem_spec.rb.tt', "spec/sample_spec.rb")
    copy('newgem/spec/integration/sample_integration_spec.rb', "spec/integration/sample_integration_spec.rb")

    if @options[:edit]
      run("#{@options['edit']} \"#{gemspec_dest}\"")  # Open gemspec in editor
    end
  end

  private

  def copy(from, to)
    @thor.template(File.join(from), File.join(@target, to), @opts)
  end

  def gem_options
    constant_name = get_constant_name
    constant_array = constant_name.split('::')
    git_user_name = `git config user.name`.chomp
    git_user_email = `git config user.email`.chomp

    opts = {
      name: @name,
      namespaced_path: @namespaced_path,
      constant_name: constant_name,
      constant_array: constant_array,
      author: git_user_name.empty? ? 'TODO: Write your name' : git_user_name,
      email: git_user_email.empty? ? 'TODO: Write your email address' : git_user_email,
      test: @options[:test],
      volt_version_base: volt_version_base
    }

    opts
  end

  def volt_version_base
    require 'volt/version'
    Volt::Version::STRING
  end

  def get_constant_name
    constant_name = @name.split('_').map { |p| p[0..0].upcase + p[1..-1] }.join
    constant_name = constant_name.split('-').map { |q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/

    constant_name
  end

  def yes?(msg)
    @shell.yes?(msg)
  end
end
