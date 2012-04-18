require 'ipaddr'

module Netconf
  module IpParser
    class IpRange
      include Comparable

      @@is_any = /^any$/i

      @@ipv4   = /(?:\d{1,3}\.){3}\d{1,3}/
      @@ipv6_1 = /(?:[0-9a-f]{1,4}:){7}(?:[0-9a-f]{1,4})/ # matches full length (16 byte) address including fields with leading zeros dropped
      @@ipv6_2 = /(?:[0-9a-f]{1,4}:)*(?::[0-9a-f]{1,4})*/ # matches address with ommitted string of zeros in the middle (ffff::ffff)
      @@ipv6_3 = /(?:[0-9a-f]{1,4}:)*:/ # matches address with ommitted string of zeros at the front (::ffff)
      @@ipv6_4 = /:(?::[0-9a-f]{1,4})*/ # matches address with ommitted string of zeros at the end (ffff::)
      @@ip     = /#{@@ipv4}|#{@@ipv6_1}|#{@@ipv6_2}|#{@@ipv6_3}|#{@@ipv6_4}/

      def <=>(other)
        ip_start.to_i <=> other.ip_start.to_i
      end

      def ==(other)
        return ip_start.to_i == other.ip_start.to_i && ip_end.to_i == other.ip_end.to_i
      end

      def adjacent?(other)
        if (@ip_end.to_i == other.ip_start.to_i || @ip_end.to_i + 1 == other.ip_start.to_i)
          return true
        end
        return false
      end

      def contains?(other)
        if (@ip_start.to_i <= other.ip_start.to_i && @ip_end.to_i >= other.ip_end.to_i)
          return true
        end
      end

      def eql?(other)
        return self == other
      end

      def ip_start
        return @ip_start
      end

      def ip_start=(ip)
        if (ip.to_i < @ip_start.to_i)
          raise ip.to_s + " is lower then existing start ip of " + @ip_start.to_s
        end
        @ip_start = ip
      end

      def ip_end
        return @ip_end
      end

      def ip_end=(ip)
        if (ip.to_i < @ip_end.to_i)
          raise ip.to_s + " is lower then existing end ip of " + @ip_end.to_s
        end
        @ip_end = ip
      end

      def networks
        networks = Array.new
        start_address = @ip_start.to_i
        end_address = @ip_end.to_i

        if (@ip_start.ipv4?)
          maxlen = 32
          cidr = 32
        else
          maxlen = 128
          cidr = 128
        end
        next_address = nil
        last_address = end_address + 1

        # loop until the ip we're working with is equal to the
        # end address
        while start_address <= end_address
          # if the modulus (remainder) of the start address raised to
          # the power of the cidr is equivalent to zero then it means
          # the starting address is on the current cidr's subnet boundary
          if (start_address % 2**cidr == 0)
            # increment the nextaddress by one whole subnet
            next_address = start_address + 2**cidr

            # if the next address is past the end address then we have
            # to look for a smaller subnet size, otherwise we've found
            # our next network.  Print to the screen and look for the next
            # subnet
            if (next_address > last_address)
              cidr-=1
            else 
              tip = IPAddr.new(start_address, @ip_start.family)
              tip = tip.mask(maxlen-cidr)
              networks.push(tip)
              start_address = start_address + 2**cidr
              cidr+=1
            end
            # if startAddress % 2**cidr != 0 then we need to look for a smaller
            # subnet size
          else
            cidr-=1
          end
        end
        return networks
      end

      def parse(address)
        # there are a number of possible formats a string might be in to 
        # represent an IP address range.  The IpAddr class recognizes
        # ip/mask, and ip/cidr by default.  We also want to accept
        # ip-ip to allow a non-subnet range

        # take care of 'any' keyword.  This maps to 0.0.0.0/0 v4 address
        if (address =~ @@is_any)
          @ip_start = IPAddr.new("0.0.0.0");
          @ip_end = IPAddr.new("255.255.255.255");
        # take care of the default cases
        elsif (address =~ /^#{@@ip}$/)
          @ip_start = IPAddr.new(address)
          @ip_end = @ip_start
        elsif (match = /^(.+)\/(.+)$/.match(address))
          @ip_start = IPAddr.new(address)
          @ip_end = @ip_start.broadcast

          ip_check = IPAddr.new(match[1])
          if (ip_check.to_i != @ip_start.to_i)
            STDERR.print ArgumentError.new("#{match[1]} does not fall on a /#{match[2]} (valid is #{@ip_start}) boundary")
            STDERR.print "\n"
          end
        # match two complete IPs
        elsif (match = /^(#{@@ip})-(#{@@ip})$/.match(address))
          ip_1 = match[1]
          ip_2 = match[2]
          @ip_start = IPAddr.new(ip_1)
          @ip_end = IPAddr.new(ip_2)
        # match an IP followed by the last octet
        elsif (match = /^(#{@@ip})-([0-9a-f]+)$/.match(address))
          ip_1 = match[1]
          last_octet = match[2]
          ip_2 = ip_1
          ip_2 = ip_2.gsub(/[0-9a-f]+$/, last_octet)
          @ip_start = IPAddr.new(ip_1)
          @ip_end = IPAddr.new(ip_2)
        else
          raise ArgumentError.new("#{address} is not a recognized IP address or range")
        end
      end

      def to_s
        return @ip_start.to_s + "-" + @ip_end.to_s
      end

      def initialize(value)
        if (value.is_a? IPAddr)
          value = "#{value.to_s}/#{value.prefix}"
        end
        begin
          parse value.to_s
        rescue => e
          raise e.class.new("#{e.message} for #{value}")
        end
      end

    end
  end
end
