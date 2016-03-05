# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acorn_cache/version'

Gem::Specification.new do |spec|
  spec.name          = "acorn_cache"
  spec.version       = AcornCache::VERSION
  spec.authors       = ["Vincent J. DeVendra", "Perry Carbone"]
  spec.email         = ["VinceDeVendra@gmail.com", "perrycarb@gmail.com"]

  spec.description       = "AcornCache is a Ruby HTTP proxy caching library that is lightweight, configurable and can be easily integrated with any Rack-based web application. AcornCache allows you to improve page load times and lighten the load on your server by allowing you to implement an in-memory cache shared by every client requesting a resource on your server."
  spec.summary   = "A HTTP proxy caching library for Rack apps"
  spec.homepage      = "https://github.com/acorncache/acorn-cache"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "mocha"
  spec.add_runtime_dependency "rack", "~> 1.6"
  spec.add_runtime_dependency "redis"
  spec.add_runtime_dependency "dalli"
  spec.add_runtime_dependency 'concurrent-ruby'
end
