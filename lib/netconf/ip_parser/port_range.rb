
module Netconf
  module IpParser
    class PortRange
      include Comparable

      @@is_any        = /^any$/
      @@is_port       = /^(\d+)$/
      @@is_port_range = /^(\d+)-(\d+)$/

      def <=>(other)
        @port_start <=> other.port_start
      end

      def ==(other)
        return @port_start == other.port_start && port_end == other.port_end
      end

      def adjacent?(other)
        if (@port_end == other.port_start || @port_end + 1 == other.port_start)
          return true
        end
        return false
      end

      def contains?(other)
        if (@port_start <= other.port_start && @port_end >= other.port_end)
          return true
        end
        return false
      end

      def eql?(other)
        return self == other
      end

      def port_start
        return @port_start
      end

      def port_start=(port)
        if (port < @port_start)
          raise port.to_s + " is lower then existing starting port of " + @port_start.to_s
        end
        @port_start = port
      end

      def port_end
        return @port_end
      end

      def port_end=(port)
        if (port < @port_end)
          raise port.to_s + " is lower then existing end port of " + @port_end.to_s
        end
        @port_end = port
      end

      def parse(value)
        if (value =~ @@is_any)
          @port_start = 1
          @port_end = 65535
        elsif (value =~ @@is_port)
          @port_start = $1.to_i
          @port_end = $1.to_i
        elsif (value =~ @@is_port_range)
          @port_start = $1.to_i
          @port_end = $2.to_i
        else
          raise value + " is not a valid port range"
        end

        if (@port_start < 0 || @port_start > 65535 ||
            @port_end < 0 || @port_end > 65535 ||
            @port_start > @port_end)
          raise value + " is an invalid port range"
        end
      end

      def to_s
        if (@port_start == @port_end)
          @port_start.to_s
        else
          @port_start.to_s + "-" + @port_end.to_s
        end
      end

      def initialize(value)
        parse value.to_s
      end

    end
  end
end
