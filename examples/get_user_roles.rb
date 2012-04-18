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

  realm_name = 'radius'
  user_name = 'abates'

  roles = n.get_mapping_roles(realm_name, user_name.upcase)
  puts roles.inspect
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

