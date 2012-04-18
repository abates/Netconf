

module Netconf
  class NetconfReader
    def initialize input, args={}
      raise "Input MUST be an IO object.  Supplied input was #{input.class}" unless (input.is_a? IO)
      @source = input
      @readers = []
      @destination, @writer = IO.pipe
      @readers.push(@destination)
      @eom = '\]\]>\]\]>[\r\n]+'
      @partial_eom = '(?:\])|(?:\]\])|(?:\]\]\>)|(?:\]\]\>\])|(?:\]\]\>\]\])$'
      @debug = args[:debug] || false

      Thread.abort_on_exception = true
      Thread.new do
        read_loop
      end
    end

    def reader
      @readers.shift
    end

    private
      def read_loop
        buff = nil
        while (true)
          begin
            if (buff.nil?)
              buff = @source.readpartial(4096)
              print buff if (@debug)
            else
              append = @source.readpartial(4096)
              buff << append
              print append if (@debug)
            end
          rescue EOFError => e
            @writer.flush
            @writer.close
            break
          rescue IOError => e
          end
          if (match=/#{@eom}/.match(buff))
            @writer.write(match.pre_match)
            @writer.flush
            @writer.close
            "#{match.post_match}".split(//).reverse.each do |c|
              @source.ungetc(c[0])
            end
            #@destination, @writer = BufferedReader.pipe(:debug => @debug)
            @destination, @writer = IO.pipe
            @readers.push(@destination)
            buff = nil
          elsif (buff =~ /#{@partial_eom}$/)
            next
          else
            @writer.write(buff)
            buff = nil
          end
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
