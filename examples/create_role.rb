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

  n.new_role('bates test role 1', 'test description')
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

