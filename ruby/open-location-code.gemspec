# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'date'

Gem::Specification.new do |s|
  s.name          = 'open-location-code'
  s.version       = '1.0.4'
  s.authors       = ['Google', 'Wei-Ming Wu']
  s.date          = Date.today.to_s
  s.email         = ['open-location-code@googlegroups.com',
                     'wnameless@gmail.com']
  s.summary       = 'Ruby implementation of Open Location Code (Plus Codes)'
  s.description   = s.summary
  s.homepage      = 'https://github.com/google/open-location-code'
  s.license       = 'Apache License, Version 2.0'

  s.files         = Dir['lib/**/*']
  s.test_files    = Dir['test/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.6.0'

  s.add_development_dependency 'test-unit'
end
