# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-frost/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-frost'
  spec.version       = CocoapodsFrost::VERSION
  spec.authors       = ['Hiroshi Kimura - Muukii']
  spec.license       = 'MIT'
  spec.summary       = ''
  spec.description   = <<~DESC
  DESC
  spec.homepage      = 'https://github.com/muukii/cocoapods-frost'
  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'cocoapods', '>= 1.10', '< 2.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
end
