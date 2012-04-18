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

  routes = n.get_ipsec_routes('bates')
  routes.each do |route|
    if (route.for_role?('bates-test-dmi'))
      puts "#{route.to_yml}"
    end
  end
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

