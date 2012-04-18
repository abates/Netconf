require "netconf/ip_parser/generic_collection"
require "set"

module Netconf
  module IpParser
    class PortCollection < GenericCollection
      attr_accessor :ports

      def initialize(values)
        @ports = Set.new
        if (values.is_a?(Array))
          values.each do |port|
            if (port.is_a?(PortRange))
              @ports.add(port)
            else
              @ports.add(PortRange.new(port))
            end
          end
        elsif (!values.nil?)
          values.split(/[,\r\n\s]+/).each do |port|
            port = port.strip
            next if (port.empty?)
            @ports.add(IpParser::PortRange.new(port))
          end
        end
      end

      def add(port)
        @ports.add(port)
      end

      def complement port_collection
        return subtract_rhs(port_collection.ports, @ports)
      end

      def contains? port_collection
        return complement(port_collection).size == 0
      end

      def extra? port_collection
        return extra(port_collection).size != 0
      end

      def extra port_collection
        return subtract_lhs(@ports, port_collection.ports)
      end

      def minimize
        minimum_ranges = Array.new
        last_range = nil
        # combine adjacent ranges and remove
        # ranges contained within other ranges
        @ports.sort.each do |port_range|
          if (last_range.nil?)
            minimum_ranges.push(port_range)
            last_range = port_range
          elsif (! last_range.contains?(port_range))
            if (last_range.adjacent?(port_range))
              last_range.port_end = port_range.port_end
            else
              minimum_ranges.push(port_range)
              last_range = port_range
            end
          end
        end
        return minimum_ranges
      end

      def to_s
        @ports.to_a().join(", ")
      end
    end
  end
end
