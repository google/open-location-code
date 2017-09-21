# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "date"

Gem::Specification.new do |s|
  s.name          = "open-location-code"
  s.version       = "1.0.2"
  s.authors       = ["Wei-Ming Wu"]
  s.date          = Date.today.to_s
  s.email         = ["wnameless@gmail.com"]
  s.summary       = %q{Ruby implementation of Google Open Location Code(Plus+Codes)}
  s.description   = s.summary
  s.homepage      = "https://github.com/google/open-location-code"
  s.license       = "Apache License, Version 2.0"

  s.files         = Dir["lib/**/*"]
  s.test_files    = Dir["test/**/*"]
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.7"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "test-unit"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "yard"
end
