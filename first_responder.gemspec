# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'first_responder/version'

Gem::Specification.new do |spec|
  spec.name          = "first_responder"
  spec.version       = FirstResponder::VERSION
  spec.authors       = ["Curtis Ekstrom"]
  spec.email         = ["curtis@wellmatchhealth.com"]
  spec.description   = %q{A small library to coerce and validate API responses using PORO's.}
  spec.summary       = %q{FirstResponder classes wrap API responses and define the attributes required of those responses.}
  spec.homepage      = "https://github.com/clekstro/first_responder"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "virtus"
  spec.add_dependency "activemodel"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"

end
