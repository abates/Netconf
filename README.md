Netconf
=======

Introduction
------------

Ruby implementation of some Netconf (RFC 6241) capabilities.  In addition
to the Netconf base capabilities, there is specific support for managing 
Juniper Infranet Controllers

For examples of use with a Juniper Infranet confoller see the code in
the examples/ directory

Examples
--------

### Connecting to a device (default port 22)
    begin
      n = Netconf::Factory.create(
        :transport => 'ssh',
        :login => 'username',
        :password => 'password',
        :hostname => 'host.example.com' 
      )
    rescue Netconf::RPCException => e
      puts "RPCException received:"
      e.errors.each do |error|
        puts "\t#{error.error_message}"
      end
    end

### Connecting to a device (alternate port)
    begin
      n = Netconf::Factory.create(
        :transport => 'ssh',
        :login => 'username',
        :password => 'password',
        :hostname => 'host.example.com',
        :port => 830
      )
    rescue Netconf::RPCException => e
      puts "RPCException received:"
      e.errors.each do |error|
        puts "\t#{error.error_message}"
      end
    end

### Getting the entire config
    begin
      n = Netconf::Factory.create(
        :transport => 'ssh',
        :login => 'username',
        :password => 'password',
        :hostname => 'host.example.com',
        :port => 830
      )
      config = n.get_config
    rescue Netconf::RPCException => e
      puts "RPCException received:"
      e.errors.each do |error|
        puts "\t#{error.error_message}"
      end
    end

### Getting a specific block of config
    begin
      n = Netconf::Factory.create(
        :transport => 'ssh',
        :login => 'username',
        :password => 'password',
        :hostname => 'host.example.com',
        :port => 830
      )
      filter = <<_EOF
       <t:top xmlns:t="http://example.com/schema/1.2/config">
         <t:interfaces>
           <t:interface t:ifName="eth0"/>
         </t:interfaces>
       </t:top>
      _EOF
      config = n.get_config(filter)
    rescue Netconf::RPCException => e
      puts "RPCException received:"
      e.errors.each do |error|
        puts "\t#{error.error_message}"
      end
    end

### Setting a config value

We use builder to build XML blocks to send to the device.  This is very efficient since
the xml is being sent to the device (as opposed to being built in memory) as it is
being built.  It is very easy to send config in an "edit-config" operation using builder,
simply supply a block to the edit_config method.  When called, the block will be passed an
instance of the builder object.

    begin
      n = Netconf::Factory.create(
        :transport => 'ssh',
        :login => 'username',
        :password => 'password',
        :hostname => 'host.example.com',
        :port => 830
      )
      n.edit_config('running') do |xml|
        xml.top( 'xmlns' => 'http://example.com/schema/1.2/config') do
          xml.interface do
            xml.name 'Ethernet0/0'
            xml.mtu '1500'
          end
        end
      end
    rescue Netconf::RPCException => e
      puts "RPCException received:"
      e.errors.each do |error|
        puts "\t#{error.error_message}"
      end
    end


### Adding new capabilities

It is also very easy to add new capabilities.  Capabilities are added in the form of
Ruby modules.  Any module that implements a set of capabilities need only have a
has_capability? method that will return true for a matching capability in the 
Netconf hello received for the device.  The Ruby Netconf API will iterate all the
modules in the capabilities directory and will include them in the Device class if
the has_capability? returns true.

    module MyCapabilities

      def self.has_capability? capability
        capability =~ /http:\/\/example.net\/router\/2.3\/myfeature/
      end

      def myfeature
        # do whatever you need to do here
      end
    end

For more detailed use please see the existing capabilities in lib/netconf/capabilities/


