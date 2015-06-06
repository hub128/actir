require 'yaml'

module Actir
  module Webdriver
    module Devices
      
      def devices
        Actir::Config.get_content(config_file)
      end
      
      def resolution_for(device_name, orientation)
        device = devices[device_name.downcase][orientation.downcase]
        [device[:width],device[:height]]
      end
      
      def agent_string_for(device)
        device = (device ? device.downcase : :iphone)
        user_agent_string = devices[device][:user_agent]
        raise "Unsupported user agent: '#{device}'." unless user_agent_string
        user_agent_string
      end

      private

      def config_file
        File.join(Pathname.new(File.dirname(__FILE__)).realpath, "config/devices.yaml")
      end
      
    end
  end
end