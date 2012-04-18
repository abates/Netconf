#!/usr/bin/ruby

require 'example_helper'
require 'pp'

if (ARGV.length < 1)
  STDERR.print "Usage: #{$0} <vzid1> <vzid2> <vzid3> ...\n"
  exit -1
end

def get_route role_name, resources
  role_routes = []
  resources.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/[^\s:]+/) do |ip|
    @routes.each do |route|
      if (route.for_role?(role_name) && route.include?(ip))
        role_routes.push route.name
      end
    end
  end
  role_routes
end

begin
  ic = @icinfo[:prod]
  n = Netconf::Factory.create(
    :transport => 'ssh',
    :login => ic[:login],
    :password => ic[:password],
    :hostname => ic[:hostname]
  )

  @realms = n.get_realm()
  @resources = n.get_resources()
  @routes = n.get_ipsec_routes()
  @realms.each do |realm|
    ARGV.each do |id|
      roles = realm.roles(id)
      if (roles.length > 0)
        puts "#{@text_bright}#{@text_white}Realm: #{realm.name}#{@text_normal}"
        roles.each do |role_name|
          next if (role_name =~ /^\s*$/)
          puts "\t#{role_name}"
            @resources.each do |resource|
              if (resource.for_role?(role_name))
                if (resource.resources.nil?)
                  puts "\t\t#{@text_bright}#{@text_red}NO RESOURCES DEFINED IN ACCESS POLICY: \"#{resource.name}\"#{@text_normal}"
                else
                  resource.resources.each do |r|
                    print "\t\t#{r}"
                    rou = get_route(role_name, r)
                    if (rou.length == 0)
                      puts "  #{@text_red}NOT DEFINED IN ANY ROUTE POLICY!#{@text_normal}"
                    else
                      puts "  #{@text_green}#{rou.inspect}#{@text_normal}"
                    end
                  end
                end
              end
            end
        end
      end
    end
  end
rescue Netconf::RPCException => e
  puts "RPCException received:"
  pp e.errors
end
