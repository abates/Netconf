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
  role_name = 'bates test role 1'

  n.add_role_to_resource(resource_name, role_name)
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

