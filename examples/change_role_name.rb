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

  new_name = 'OACUsers'
  old_name = 'OACUsers - name changed!'

  puts "============================================================="
  users = n.get_role_mappings(old_name).collect {|name, mappings| [name, mappings.collect {|name, roles| name}]}
  puts "         Users (before rename): #{users.inspect}"
  resources = n.get_role_resources(old_name)
  puts "     Resources (before rename): #{resources.inspect}"
  policies = n.get_role_ipsec_policies(old_name)
  puts "IPSec Policies (before rename): #{policies.inspect}"
  puts "============================================================="

  puts "Renaming....."
  n.change_role_name(old_name, new_name)

  puts "============================================================="
  users = n.get_role_mappings(new_name).collect {|name, mappings| [name, mappings.collect {|name, roles| name}]}
  puts "         Users (after rename): #{users.inspect}"
  resources = n.get_role_resources(new_name)
  puts "     Resources (after rename): #{resources.inspect}"
  policies = n.get_role_ipsec_policies(new_name)
  puts "IPSec Policies (after rename): #{policies.inspect}"
  puts "============================================================="
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

