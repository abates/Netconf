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

  role_name = 'OACUsers'

  resources = n.get_role_resources(role_name)
  puts resources.inspect
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

