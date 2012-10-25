#!/usr/bin/env ruby
# 
# == Cloud Load Balancers API
# ==== Connects Ruby Applications to Rackspace's {Cloud Load Balancers service}[http://www.rackspacecloud.com/cloud_hosting_products/servers]
# By H. Wade Minter <minter@lunenburg.org>
#
# See COPYING for license information.
# Copyright (c) 2011, Rackspace US, Inc.
# ----
# 
# === Documentation & Examples
# To begin reviewing the available methods and examples, peruse the README.rodc file, or begin by looking at documentation for the 
# CloudLB::Connection class.
#
# The CloudLB class is the base class.  Not much of note aside from housekeeping happens here.
# To create a new CloudLB connection, use the CloudLB::Connection.new method.

module CloudLB
  
  AUTH_USA = "https://auth.api.rackspacecloud.com/v1.0"
  AUTH_UK = "https://lon.auth.api.rackspacecloud.com/v1.0"

  require 'uri'
  require 'rubygems'
  require 'json'
  require 'date'
  require 'typhoeus'

  unless "".respond_to? :each_char
    require "jcode"
    $KCODE = 'u'
  end

  $:.unshift(File.dirname(__FILE__))
  require 'cloudlb/version'
  require 'cloudlb/exception'
  require 'cloudlb/authentication'
  require 'cloudlb/connection'
  require 'cloudlb/balancer'
  require 'cloudlb/node'
  require 'cloudlb/health_monitor'
  require 'cloudlb/connection_throttle'
  require 'cloudlb/ssl_termination'

  # Helper method to recursively symbolize hash keys.
  def self.symbolize_keys(obj)
    case obj
    when Array
      obj.inject([]){|res, val|
        res << case val
        when Hash, Array
          symbolize_keys(val)
        else
          val
        end
        res
      }
    when Hash
      obj.inject({}){|res, (key, val)|
        nkey = case key
        when String
          key.to_sym
        else
          key
        end
        nval = case val
        when Hash, Array
          symbolize_keys(val)
        else
          val
        end
        res[nkey] = nval
        res
      }
    else
      obj
    end
  end
  
  def self.hydra
    @@hydra ||= Typhoeus::Hydra.new
  end
  
  # CGI.escape, but without special treatment on spaces
  def self.escape(str,extra_exclude_chars = '')
    str.gsub(/([^a-zA-Z0-9_.-#{extra_exclude_chars}]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end
  end
  
  def self.paginate(options = {})
    path_args = []
    path_args.push(URI.encode("limit=#{options[:limit]}")) if options[:limit]
    path_args.push(URI.encode("offset=#{options[:offset]}")) if options[:offset]
    path_args.join("&")
  end
  

end
