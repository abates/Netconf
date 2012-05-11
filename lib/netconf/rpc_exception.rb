module Netconf
  class RPCException < StandardError

    attr_reader :errors

    def initialize errors
      if (errors.is_a? Array)
        @errors = Array.new(errors)
      else
        @errors = []
        @errors.push errors
      end
      super(@errors.collect{|e| e.error_message}.join("\n"))
    end
  end
end
