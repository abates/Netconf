
require 'test/unit'
require 'netconf/connection'

class ConnectionTest < Test::Unit::TestCase
  class TestConnection < Netconf::Connection::Base
    attr_reader :pipe_read, :pipe_write
    def initialize
      super
      (@read, @pipe_write) = IO.pipe
      (@pipe_read, @write) = IO.pipe
    end
  end

  def setup
    @connection = TestConnection.new
  end

  def test_create
    assert_not_nil @connection
  end

  def test_read
    @connection.pipe_write.write("message1\n]]>]]>\nmessage2\n")
    @connection.pipe_write.close
    @connection.recv do |ins|
      message = ins.read
      assert_equal "message1\n", message
    end

    @connection.recv do |ins|
      message = ins.read
      assert_equal "message2\n", message
    end
  end

  def test_write
    @connection.send do |out|
      out.write "message1\n"
    end
    message = @connection.pipe_read.read_nonblock 1024
    assert_equal "message1\n]]>]]>\n", message
  end

  def test_close
    @connection.close
    assert @connection.closed?
  end
end
