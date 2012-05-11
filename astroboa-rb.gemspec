# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "astroboa-rb/version"

Gem::Specification.new do |s|
  s.name = "astroboa-rb"
  s.version = Astroboa::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["BetaCONCEPT","Gregory Chomatas"]
  s.email = ["support@betaconcept.com"]
  s.homepage = "http://www.astroboa.org"
  s.date = Date.today.to_s
  s.summary = %q{Astroboa Client for Ruby.}
  s.description = %q{Provides easy access to the REST-based 'Astroboa Resource API'. With just a few lines of code you can read, write and search semi-structured content to any astroboa repository hosted in any server in the world.}

  s.rubyforge_project = "astroboa-rb"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'rest-client','>= 1.6'
  s.add_runtime_dependency 'json','>= 1.6'
  s.add_development_dependency 'cucumber','~> 1.1'
  s.add_development_dependency 'rspec-expectations','~> 2.8'
end
