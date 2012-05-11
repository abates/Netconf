#!/usr/bin/ruby

require 'netconf/connection'
require 'expect'
require 'pty'

module Netconf
  module Connection
    # The SSH connection will spawn an SSH command on the system
    # and connect to the host with a given username and password
    # this allows Netconf functionality to ride an SSH session
    # as the transport
    class SystemSsh < Netconf::Connection::Base
      def initialize configuration
        super(configuration)
        @timeout = configuration[:timeout] || 60
        @login_timeout = configuration[:login_timeout] || 10
        port = configuration[:port] || 22

        hostname = configuration[:hostname]
        login = configuration[:login]
        password = configuration[:password]

        if (hostname.nil? || login.nil? || password.nil?)
          raise "Hostname, login and password must all be set in the configuration argument"
        end

        (@read, @write, @pid) = PTY.spawn("stty -echo; /usr/bin/ssh -l #{login} #{hostname} netconf")
        r = @read.expect(/password:/i, @login_timeout)
        if (r.nil?)
          raise "Failed to authenticate to host #{hostname}"
        end
        @write.write("#{password}\n")
        @write.flush
      end
    end
  end
end

