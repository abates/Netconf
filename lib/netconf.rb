require 'netconf/device'
require 'netconf/connection'

module Netconf
  module Factory
    def self.get_class path, file, mod
      class_name = file.classify
      class_name.gsub!(/\.rb$/, '')
      require "#{path}/#{file}"
      begin
        klass = mod.const_get(class_name)
      rescue NameError => e
        raise "Expected #{path}/#{file} to declare #{class_name}"
      end
      return klass
    end

    def self.create configuration
      raise "Transport must be specified" if (configuration[:transport].nil?)
      transport_file = "#{configuration[:transport]}.rb"
      path = File.expand_path('../netconf/connection', __FILE__)
      raise "Could not find transport #{path}/#{transport_file}" unless (File.exists?("#{path}/#{transport_file}"))
      c = get_class(path, transport_file, Netconf::Connection)
      return Netconf::Device.new(c.new(configuration))
    end
  end
end

