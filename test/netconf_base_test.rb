
require 'netconf/connection/pipe'
require 'netconf/device'
require 'netconf/connection_exception'
require 'xml'
require 'test/unit'

class NetconfBaseTest < Test::Unit::TestCase
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

  def test_capabilities
    @connection.pipe_write.close
    d = Netconf::Device.new(@connection)
    assert d.remote_capabilities.include?("urn:ietf:params:xml:ns:netconf:base:1.0"), "Netconf Base capability not found"
    assert d.respond_to?(:get_config), "Netconf Base capability found but get_config method not implemented"
    assert d.respond_to?(:edit_config), "Netconf Base capability found but edit_config method not implemented"
    assert d.respond_to?(:copy_config), "Netconf Base capability found but copy_config method not implemented"
    assert d.respond_to?(:delete_config), "Netconf Base capability found but delete_config method not implemented"
    assert d.respond_to?(:lock), "Netconf Base capability found but lock method not implemented"
    assert d.respond_to?(:unlock), "Netconf Base capability found but unlock method not implemented"
    assert d.respond_to?(:get), "Netconf Base capability found but get method not implemented"
    assert d.respond_to?(:close_session), "Netconf Base capability found but close_session method not implemented"
    assert d.respond_to?(:kill_session), "Netconf Base capability found but kill_session method not implemented"
  end

  def test_get_config
    @connection.pipe_write.write "#{@rpc_reply}]]>]]>\n"
    @connection.pipe_write.flush

    d = Netconf::Device.new(@connection)
    @connection.pipe_read.read_nonblock(1024)

    filter = "<config><value /></config>"
    output = ""
    d.get_config filter, 'running' do |reader|
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


