# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = "volt"
  spec.version       = version
  spec.authors       = ["Ryan Stout"]
  spec.email         = ["ryan@agileproductions.com"]
  spec.summary       = %q{A ruby web framework where your ruby runs on both server and client (via Opal)}
  # spec.description   = %q{}
  spec.homepage      = "http://voltframework.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.18.0"
  spec.add_dependency "pry", "~> 0.9.12.0"
  spec.add_dependency "rspec", "3.0.0.beta1"
  spec.add_dependency "nokogiri", "~> 1.6.0"
  spec.add_dependency "rack", "~> 1.5.0"
  spec.add_dependency "sprockets-sass", "~> 1.0.0"
  spec.add_dependency "sass", "~> 3.2.5"
  spec.add_dependency "mongo", "~> 1.9.0"
  spec.add_dependency "bson_ext", "~> 1.9.0"
  spec.add_dependency "thin", "~> 1.6.0"
  spec.add_dependency "multi_json", "~> 1.8.2"
  spec.add_dependency "oj", "~> 2.5.0"
  spec.add_dependency "rake", "~> 10.0.4"
  spec.add_dependency "listen", "~> 2.4.0"
  # spec.add_dependency "rack-colorized_logger", "~> 1.0.4"


  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "guard", "2.0.1" # bug in current guard
  spec.add_development_dependency "guard-rspec", "~> 1.2.0"
  spec.add_development_dependency "opal-rspec", "0.3.0.beta2"
  spec.add_development_dependency "yard", "~> 0.8.7.0"
end
