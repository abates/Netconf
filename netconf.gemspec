# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "netconf/version"

Gem::Specification.new do |s|
  s.name        = "netconf"
  s.version     = Netconf::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrew Bates"]
  s.email       = ["andrew.bates@verizon.com"]
  s.homepage    = "https://github.com/abates/Netconf"
  s.summary     = %q{This gem provides a Ruby API into Juniper's Netconf interface on Infranet Controllers}
  s.description = %q{see summary}

  s.rubyforge_project = ""

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('libxml-ruby', '>= 2.2.2')
  s.add_dependency('builder', '>= 3.0.0')
  s.add_dependency('net-ssh', '>= 2.0.0')
end
