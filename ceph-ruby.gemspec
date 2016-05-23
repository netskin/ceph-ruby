# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ceph-ruby/version'

Gem::Specification.new do |gem|
  gem.name          = 'ceph-ruby'
  gem.version       = CephRuby::VERSION
  gem.authors       = ['Netskin GmbH', 'Corin Langosch']
  gem.email         = ['info@netskin.com', 'info@corinlangosch.com']
  gem.description   = 'Easy management of Ceph'
  gem.summary       = 'Easy management of Ceph Distributed Storage System'
  gem.homepage      = 'http://github.com/netskin/ceph-ruby'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($RS)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'ffi', '~> 1.9'
  gem.add_dependency 'activesupport', '~> 3.0'
  gem.add_development_dependency 'guard', '~> 2.13'
  gem.add_development_dependency 'guard-rake', '~> 1.0'
  gem.add_development_dependency 'guard-rspec', '~> 4.6'
  gem.add_development_dependency 'guard-bundler', '~> 2.1'
  gem.add_development_dependency 'rubocop', '~> 0.39'
  gem.add_development_dependency 'rspec', '~> 3.4'
  gem.add_development_dependency 'rake', '~> 11.1'
  gem.add_development_dependency 'bundler', '~> 1.3'
end
