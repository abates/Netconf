

module Netconf
  class NetconfReader
    def initialize args={}
      @readers = []
      @destination, @writer = IO.pipe
      @readers.push(@destination)
      @eom = '\]\]>\]\]>[\r\n]+'
      @partial_eom = '(?:\])|(?:\]\])|(?:\]\]\>)|(?:\]\]\>\])|(?:\]\]\>\]\])$'
      @debug = args[:debug] || false
    end

    def reader
      @readers.shift
    end

    def close
      @writer.flush
      @writer.close
    end

    def read_loop(input)
      raise "Input MUST be an IO object.  Supplied input was #{input.class}" unless (input.is_a? IO)
      Thread.abort_on_exception = true
      Thread.new do
        buff = nil
        while (true)
          begin
            if (buff.nil?)
              buff = input.readpartial(4096)
              print buff if (@debug)
            else
              append = input.readpartial(4096)
              buff << append
              print append if (@debug)
            end
          rescue EOFError => e
            unless (buff.nil? || buff.empty?)
              @writer.write(buff)
            end
            close
            break
          rescue IOError => e
          end
          buff = consume(buff)
        end
      end
    end

    def consume data
      if (match=/#{@eom}/.match(data))
        @writer.write(match.pre_match)
        @writer.flush
        @writer.close
        @destination, @writer = IO.pipe
        @readers.push(@destination)
        post_match = match.post_match
        if (post_match =~ /#{@eom}/)
          return consume(post_match)
        else
          return match.post_match
        end
      elsif (data =~ /#{@partial_eom}$/)
        return data
      else
        @writer.write(data)
        return nil
      end
    end
  end

  class BufferedReader
    def self.pipe(options={})
      reader, writer = IO.pipe
      buffered_reader = BufferedReader.new(reader, options)
      return [buffered_reader, writer]
    end

    def initialize(reader, args={})
      @reader = reader
      @debug = args[:debug] || false
     end 

    def read length=nil, buffer=nil
      ret = @reader.read(length, buffer)
      print "#{ret}" if (@debug)
      return ret
    end

    def readline sep_string=$/
      line = @reader.readline(sep_string)
      print "#{line}" if (@debug)
      return line
    end

    def method_missing(name, *args)
      @reader.send(name, *args)
    end
  end

  class BufferedWriter
    def initialize output, args={}
      raise "Output MUST be an IO object.  Supplied output was #{output.class}" unless (output.is_a? IO)
      @destination = output
      @debug = args[:debug] || false
    end

    def << obj
      print obj.to_s if (@debug)
      @destination << obj
    end

    def write string
      print string.to_s if (@debug)
      @destination.write(string)
    end

    def method_missing(name, *args)
      @destination.send(name, *args)
    end
  end
end
