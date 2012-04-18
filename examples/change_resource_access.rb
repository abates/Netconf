#!/usr/bin/ruby

require 'example_helper'
require 'pp'

begin
  ic = @icinfo[:lab]
  n = Netconf::Factory.create(
    :transport => 'ssh',
    :login => ic[:login],
    :password => ic[:password],
    :hostname => ic[:hostname],
    :debug => true
  )

  n.set_resource_access('bates test resource', '192.168.1.0/24')
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

