
require 'netconf/buffer'

module Netconf
  module Connection
    class Base
      def initialize options={}
        @options = options
      end

      def send &block
        @buffered_writer ||= Netconf::BufferedWriter.new(@write, :debug => @options[:debug])
        block.call(@buffered_writer)
        @buffered_writer.write("]]>]]>\n")
      end

      def recv &block
        if (@netconf_reader.nil?)
          @netconf_reader = Netconf::NetconfReader.new(:debug => @options[:debug])
          @netconf_reader.read_loop(@read)
        end
        block.call(@netconf_reader.reader)
      end

      def close
        @read.close unless (@read.nil? || @read.closed?)
        unless (@write.nil?)
          @write.flush
          if (@buffered_writer.nil?)
            @write.close
          else
            @buffered_writer.close
          end
        end
      end

      def closed?
        if (@buffered_writer.nil?)
          ret = @write.closed?
        else
          ret = @buffered_writer.closed?
        end
        @read.closed? && ret
      end
    end
  end
end

