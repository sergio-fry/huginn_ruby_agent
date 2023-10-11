# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'huginn_ruby_agent'
  spec.version       = '0.2'
  spec.authors       = ['Sergei O. Udalov']
  spec.email         = ['sergei@udalovs.ru']

  spec.summary       = 'Ruby Agent for Huginn automation platform'
  spec.description   = 'Now you can write agent with Ruby-code'

  spec.homepage      = 'https://github.com/sergio-fry/huginn_ruby_agent'

  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rspec'

  spec.add_runtime_dependency 'huginn_agent'
end
