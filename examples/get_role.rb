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

  role = n.get_role('bates test role')

  name_tag = role.find_first('dmi:name', "dmi:#{role.root.namespaces.default}")
  name_tag.content = 'blah'
  puts role
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

