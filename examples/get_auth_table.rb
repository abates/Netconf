#!/usr/bin/ruby

require 'example_helper'
require 'pp'


begin
  ic = @icinfo[:prod]
  n = Netconf::Factory.create(
    :transport => 'ssh',
    :login => ic[:login],
    :password => ic[:password],
    :hostname => ic[:hostname]
  )

  auth_tables = n.get_auth_table('auth tables')
  auth_tables.each do |auth_table|
    puts auth_table.to_yml
    puts
  end


rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

