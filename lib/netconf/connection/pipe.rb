#!/usr/bin/ruby

require 'netconf/connection'

module Netconf
  module Connection
    # The Pipe connection is a dummy connection that can be used for
    # unit testing.  The Pipe will automatically create two IO.pipe
    # objects.  One has the read handle connected to the connection read
    # handle and the other has its write handle connected to the connection
    # write handle.  The pipe_read and pipe_write attributes are exposed
    # to allow data to be injected into the two pipes.
    class Pipe < Netconf::Connection::Base
      attr_reader :pipe_read, :pipe_write
      def initialize
        super
        (@read, @pipe_write) = IO.pipe
        (@pipe_read, @write) = IO.pipe
      end
    end
  end
end

