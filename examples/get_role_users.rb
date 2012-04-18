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

  role_name = 'bates test role'

  users = n.get_role_users(role_name)
  puts users.inspect
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

