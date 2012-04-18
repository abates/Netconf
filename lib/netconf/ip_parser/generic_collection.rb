
module Netconf
  module IpParser
    class GenericCollection

      def subtract_lhs lhs, rhs
        complement = Set.new
        lhs.each do |outside|
          found = false
          rhs.each do |inside|
            if (outside.contains?(inside))
              found = true
              break 
            end
          end
          if (!found)
            complement.add(outside)
          end
        end
        return complement
      end

      def subtract_rhs lhs, rhs
        complement = Set.new
        lhs.each do |outside|
          found = false
          rhs.each do |inside|
            if (inside.contains?(outside))
              found = true
              break 
            end
          end
          if (!found)
            complement.add(outside)
          end
        end
        return complement
      end
    end
  end
end
