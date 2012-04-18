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

  resource_name = 'bates test resource'
  role_name = 'bates test role'

  n.remove_role_from_resource(resource_name, role_name)
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

