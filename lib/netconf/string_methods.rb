
class String
  def classify
    new_string = ''
    split(/_/).each do |s|
      new_string += s.capitalize
    end
    new_string
  end

  def to_ip
    begin
      if (self =~ /^(?:\d{1,3}\.){3}\d{1,3}/)
        return IPAddr.new(address, Socket::AF_INET)
      elsif (self =~ /:/)
        return IPAddr.new(address, Socket::AF_INET6)
      else
        return Resolv.getaddress(self)
      end
    rescue
    end
    nil
  end

  def to_ip_range
    Netconf::IpParser::IpRange.new(self)
  end
end

