# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actir/version'

Gem::Specification.new do |spec|
  spec.name          = "actir"
  spec.version       = Actir::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["hub"]
  spec.email         = ["hub@qima-inc.com"]

  spec.summary       = %q{Application Concurrence Test in Ruby.}
  spec.description   = %q{Distribut automated testing framework for Web or App.}
  spec.homepage      = "https://github.com/hub128/actir.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files        += Dir.glob("{bin,lib}/**/*")
  spec.executables   = %w(actir ants)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "test-unit", "~> 3.0"
  spec.add_runtime_dependency "watir-webdriver", "~> 0.6.11"
  spec.add_runtime_dependency "selenium-webdriver", "~> 2.45"
  spec.add_runtime_dependency "parallel", "~> 1.4"
  spec.add_runtime_dependency "facets", "~>2.9"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
