module Netconf
  class RPCError

    attr_reader :info, :error_type, :error_tag, :error_severity

    def initialize reader
      @errors = []
      @info = []
      while (reader.read)
        break if (reader.name == 'rpc-error')
        if (reader.name == 'error-info')
          i = reader.read_inner_xml
          if (i)
            info.push(i)
          end
          next
        end
        @error_type = reader.read_inner_xml if (@error_type.nil? && reader.name == 'error-type')
        @error_tag = reader.read_inner_xml if (@error_tag.nil? && reader.name == 'error-tag')
        @error_severity = reader.read_inner_xml if (@error_severity.nil? && reader.name == 'error-severity')
        @error_message = reader.read_inner_xml if (@error_message.nil? && reader.name == 'error-message')
      end
    end

    def to_s
      "#{@error_type}:#{@error_info.inspect}"
    end
  end
end
