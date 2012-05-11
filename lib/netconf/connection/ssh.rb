#!/usr/bin/ruby

require 'netconf/connection'
require 'net/ssh'

module Netconf
  module Connection
    # This implementation uses a pury Ruby version of the SSH protocol
    # Net::SSH
    class Ssh < Netconf::Connection::Base
      def initialize configuration
        super(configuration)
        @debug = configuration[:debug]
        @timeout = configuration[:timeout] || 60
        @login_timeout = configuration[:login_timeout] || 10
        port = configuration[:port] || 22

        hostname = configuration[:hostname]
        login = configuration[:login]
        password = configuration[:password]

        if (hostname.nil? || login.nil? || password.nil?)
          raise "Hostname, login and password must all be set in the configuration argument"
        end

        @netconf_reader = Netconf::NetconfReader.new(:debug => @options[:debug])
        @ssh = Net::SSH.start(hostname, login, 
                              :port => port, 
                              :auth_methods => ['password'],
                              :password => password, 
                              :timeout => @login_timeout)
        @ssh.open_channel do |channel|
          channel.exec('netconf') do |ch, success|
            @channel = ch
            ch.on_data do |ch, data|
              print "#{data}" if (@debug)
              buff ||= ''
              buff << data
              buff = @netconf_reader.consume(buff)
            end

            ch.on_close do |ch|
              @netconf_reader.close
            end

            ch.on_eof do |ch|
              @netconf_reader.close
            end
          end
        end

        Thread.new do
          @ssh.loop(0.1)
        end
      end

      def send &block
        @destination, @writer = IO.pipe
        block.call(@writer)
        @writer.write("]]>]]>\n")
        @writer.close
        data = @destination.read

        # make sure the channel is setup
        sleep 1 while (@channel.nil?)
        print "#{data}" if (@debug)
        @channel.send_data(data)
      end
    end
  end
end

