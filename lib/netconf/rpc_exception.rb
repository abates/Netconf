module Netconf
  class RPCException < Exception

    attr_reader :errors

    def initialize errors
      super
      if (errors.is_a? Array)
        @errors = Array.new(errors)
      else
        @errors = []
        @errors.push errors
      end
    end

    def to_s
      "#{@errors.inspect}"
    end
  end
end
