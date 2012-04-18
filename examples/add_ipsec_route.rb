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
  route = routes[0]
  route.add_route('192.168.13.0/24')

  routes = n.get_ipsec_routes('bates')
  routes.each do |route|
    puts route.to_yml
    puts
  end
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end

