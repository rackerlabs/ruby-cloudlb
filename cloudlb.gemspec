# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require File.expand_path('../lib/cloudlb/version', __FILE__)
 
Gem::Specification.new do |s|
  s.name        = "cloudlb"
  s.version     = CloudLB::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["H. Wade Minter"]
  s.email       = ["minter@lunenburg.org"]
  s.homepage    = "http://github.com/rackspace/ruby-cloudlb"
  s.summary     = "Ruby API into the Rackspace Cloud Load Balancers product"
  s.description = "A Ruby API to manage the Rackspace Cloud Load Balancers product"
  s.post_install_message = %Q{
**** PLEASE NOTE **********************************************************************************************

  #{s.name} has been deprecated. Please consider using fog (http://github.com/fog/fog) for all new projects.

***************************************************************************************************************
} if s.respond_to? :post_install_message
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_runtime_dependency "typhoeus"
  s.add_runtime_dependency "json"
 
  s.files = [
    "COPYING",
    ".gitignore",
    "README.rdoc",
    "cloudlb.gemspec",
    "lib/cloudlb.rb",
    "lib/cloudlb/authentication.rb",
    "lib/cloudlb/balancer.rb",
    "lib/cloudlb/connection.rb",
    "lib/cloudlb/exception.rb",
    "lib/cloudlb/node.rb",
    "lib/cloudlb/health_monitor.rb",
    "lib/cloudlb/connection_throttle.rb",
    "lib/cloudlb/version.rb"
  ]
  s.require_path = 'lib'
end
