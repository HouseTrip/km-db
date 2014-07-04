# -*- encoding: utf-8 -*-
require File.expand_path("../lib/kmdb/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "km-db"
  s.version     = KMDB::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["HouseTrip"]
  s.email       = ["jtl@housetrip.com"]
  s.homepage    = "https://github.com/housetrip/km-db"
  s.summary     = "Process KISSmetrics data dumps"
  s.description = "Process KISSmetrics data dumps"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rspec", "~> 2.4.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "json"
  s.add_development_dependency "sqlite3-ruby"
  
  s.add_dependency "oj"
  s.add_dependency "progressbar"
  s.add_dependency "parallel"
  s.add_dependency "andand"
  s.add_dependency "activerecord", "~> 4.1"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
