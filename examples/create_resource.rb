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

  n.new_resource('bates test resource', 'test description')
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

