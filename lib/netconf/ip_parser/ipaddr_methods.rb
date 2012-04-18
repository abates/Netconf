class IPAddr

  # Return the inverse mask
  def inverse_mask
    length=32
    if (ipv6?)
      length=128
    end
    return IPAddr.new((2**length-@mask_addr-1), family)
  end

  # Return the netmask of the IP.  For instance:
  # ip = IPAddr.new("192.168.1.0/24")
  # ip.netmask
  # # would return <IPAddr: IPv4:255.255.255.0/255.255.255.255>
  def netmask
    return IPAddr.new(@mask_addr, family)
  end

  # Return the broadcast of the IP.  For instance:
  # ip = IPAddr.new("192.168.1.0/24")
  # ip.broadcast
  # # would return <IPAddr: IPv4:192.168.1.255/255.255.255.255>
  def broadcast
    length=32
    if (ipv6?)
      length=128
    end
    return IPAddr.new(to_i | 2**length - @mask_addr-1, family)
  end

  # Return the prefix of the subnet.  This is often used in CIDR notation
  # to indicate the number of bits to set in the netmask.
  #
  # ip = IPAddr.new("192.168.1.0/255.255.255.0")
  # ip.prefix
  # # would return 24
  def prefix
    return(0) if (@mask_addr == 0)
    length=32
    if (ipv6?)
      length=128
    end

    mask = nil
    netmask_int = @mask_addr
    if (netmask_int < 2**length)
        mask = length
    else
        mask = 128
    end

    mask.times do
        if ((netmask_int & 1) == 1)
            break
        end
        netmask_int = netmask_int >> 1
        mask = mask - 1
    end
    return(mask)
  end
end


