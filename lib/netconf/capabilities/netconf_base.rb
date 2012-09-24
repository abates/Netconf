#!/usr/bin/ruby

module NetconfBase
  def self.has_capability? cap
    cap =~ /urn:ietf:params:xml:ns:netconf:base:1\.0/
  end

  def execute_operation operation, options={}, &xml_block
    send_rpc do |xml|
      xml.tag!(operation) do
        {:source => {}, :target => {}, :filter => {'type' => 'subtree'}}.each do |tag, attributes|
          unless (options[tag].nil?)
            xml.tag!(tag.to_s, attributes) do
              # don't wrap xml with tags
              if (options[tag] =~ /^\s*\</)
                xml << options[tag]
              else
                xml.tag!(options[tag])
              end
            end
          end
        end
        if (xml_block.nil? && ! options[:config_block].nil?)
          xml.config("xmlns:xc" => "urn:ietf:params:xml:ns:netconf:base:1.0") do
            options[:config_block].call xml
          end
        elsif (options[:config_block].nil? && ! xml_block.nil?)
          xml_block.call xml
        elsif (! options[:config_block].nil? && ! xml_block.nil?)
          raise "Either supply a block to execute_operation or supply a :config_block option, not both!"
        end
      end
    end
    if (options[:recv_block].nil?)
      recv_rpc
    else
      recv_rpc &options[:recv_block]
    end
  end

  # Edit a piece of config in place.  The called block should produce
  # the xml config to be changed
  def edit_config target, &block
    execute_operation('edit-config', :target => target, :config_block => config_block)
  end

  # get_config will wrap the xml content created by the called block
  # with get-config tags and then pass the content to an RPC call.  The
  # method will then return the result from the server.  The block should
  # produce the appropriate XML to use as a filter to send to the remote
  # server
  #
  # If no block is passed in then the results will not be filtered and
  # the entire config returned from the server will be returned to the
  # caller
  #
  # Source should be specified as which source config to use (ie 'running').
  #
  def get_config filter, source='running', &block
    execute_operation('get-config', :source => source, :filter => filter, :recv_block => block)
  end

  def copy_config source, target='running'
    execute_operation('copy-config', :source => source, :target => target)
  end

  def delete_config target='running'
    execute_operation('delete-config', :target => target)
  end

  def lock target='running'
    execute_operation('lock', :target => target)
  end

  def unlock target='running'
    execute_operation('unlock', :target => target)
  end

  def get filter, source='running', &block
    execute_operation('get', :source => source, :filter => filter, :recv_block => block)
  end

  def close_session
    execute_operation('close-session')
  end

  # Gracefully close the netconf session with the server and close
  # the associated connection
  def close
    begin
      close_session
    rescue => e
      STDERR.puts "Failed to send or receive close-session: #{e}"
    ensure
      @connection.close
    end
  end

  def kill_session session_id
    execute_operation('kill-session') do |xml|
      xml.tag!('session-id', session_id)
    end
  end
end

