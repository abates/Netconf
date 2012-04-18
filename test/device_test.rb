
require 'netconf/connection/pipe'
require 'netconf/device'
require 'netconf/connection_exception'
require 'xml'
require 'test/unit'

class DeviceTest < Test::Unit::TestCase
  def setup
    @rpc_reply = <<_EOF
<rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <data>
    <config>
      <value>Some Value</value>
    </config>
  </data>
  <ok />
</rpc-reply>
_EOF

    @hello = <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
 <capabilities>
  <capability>urn:ietf:params:xml:ns:netconf:base:1.0</capability>
 </capabilities>
</hello>
]]>]]>
_EOF
    @connection = Netconf::Connection::Pipe.new
    @connection.pipe_write.write @hello
    @connection.pipe_write.flush
  end

  def test_initialization
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    empty_connection = Netconf::Connection::Pipe.new
    empty_connection.pipe_write.close
    assert_raise Netconf::ConnectionException do
      d = Netconf::Device.new(empty_connection)
    end
  end

  def test_capabilities
    @connection.pipe_write.close

    expected_hello = <<_EOF
<hello>
 <capabilities>
  <capability>urn:ietf:params:xml:ns:netconf:base:1.0</capability>
 </capabilities>
</hello>
]]>]]>
_EOF
    d = Netconf::Device.new(@connection)
    assert_equal expected_hello, @connection.pipe_read.read_nonblock(1024)

    assert_equal ["urn:ietf:params:xml:ns:netconf:base:1.0"], d.capabilities
  end

  def test_rpc_exception
    @connection.pipe_write.write <<_EOF
<rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
 <rpc-error>
   <error-info>Test</error-info>
   <error-type>Test</error-type>
   <error-tag>Test</error-tag>
   <error-severity>Test</error-severity>
 </rpc-error>
</rpc-reply>
]]>]]>
_EOF
    @connection.pipe_write.flush

    assert_raise Netconf::RPCException do
      d = Netconf::Device.new(@connection)
      content = d.recv_rpc
    end
  end

  def test_send_rpc
    @connection.pipe_write.close
    d = Netconf::Device.new(@connection)
    expected_response = <<_EOF
<rpc message-id="#{d.message_id + 1}">
 <config>
  <value>config value</value>
 </config>
</rpc>
]]>]]>
_EOF
    @connection.pipe_read.read_nonblock(1024)

    d.send_rpc do |xml|
      xml.config do
        xml.value "config value"
      end
    end

    response = @connection.pipe_read.read_nonblock(1024)
    assert_equal expected_response, response
  end

  def test_recv_rpc
    @connection.pipe_write.write "#{@rpc_reply}]]>]]>\n"
    @connection.pipe_write.flush

    d = Netconf::Device.new(@connection)
    content = nil
    d.recv_rpc do |reader|
      content = reader.read_inner_xml
    end
    assert content
  end

  def test_get_config
    @connection.pipe_write.write "#{@rpc_reply}]]>]]>\n"
    @connection.pipe_write.flush

    d = Netconf::Device.new(@connection)
    @connection.pipe_read.read_nonblock(1024)

    xml = "<config><value /></config>"
    output = ""
    d.get_config 'running', xml do |reader|
      output = reader.read_inner_xml
    end
    expected_output = "\n    <config xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n      <value>Some Value</value>\n    </config>\n  "
    assert_equal expected_output, output
    expected_output = <<_EOF
<rpc message-id="1">
 <get-config>
  <source>
   <running/>
  </source>
  <filter type="subtree">
<config><value /></config>  </filter>
 </get-config>
</rpc>
]]>]]>
_EOF
    output = @connection.pipe_read.read_nonblock(1024)
    assert_equal expected_output, output
  end
end


