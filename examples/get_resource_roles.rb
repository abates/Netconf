#!/usr/bin/ruby

require 'example_helper'
require 'pp'

begin
  ic = @icinfo[:lab]
  n = Netconf::Factory.create(
    :transport => 'ssh',
    :login => ic[:login],
    :password => ic[:password],
    :hostname => ic[:hostname]
  )

  resource_name = 'bates test resource'

  roles = n.get_resource_roles(resource_name)
  puts roles.inspect
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

