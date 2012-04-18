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

  auth_tables = n.get_auth_table

  n.get_roles.each do |role|
    found = false
    auth_tables.each do |auth_table|
      if (auth_table.contains?(role.name))
        puts "#{role} is in #{auth_table}"
        found = true
        break
      end
    end
    puts "#{role} WAS NOT IN ANY AUTH TABLE" unless (found)
  end
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

