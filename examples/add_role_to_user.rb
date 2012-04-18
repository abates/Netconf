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

  realm_name = 'radius'
  role_name = 'bates test role'
  user_name = 'abates'

  n.add_role_to_mapping(realm_name, user_name.upcase, role_name, [user_name])
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

