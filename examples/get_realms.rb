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

  realms = n.get_realms
  puts realms.inspect
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

