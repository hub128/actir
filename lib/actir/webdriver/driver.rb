require 'json'
require 'selenium-webdriver'
require 'actir/webdriver/browser_options'
require 'actir/webdriver/devices'

module Actir
  module Webdriver

    def self.driver options={}
      Driver.instance.for options
    end
    
    class Driver
      include Singleton
      include Devices

      def for(opts)
        user_agent_string = agent_string_for opts[:agent]
        options = BrowserOptions.new(opts, user_agent_string)
        build_driver_using options
      end

      def resize_inner_window(driver, width, height)
        if driver.browser == :firefox or :chrome
          driver.execute_script("window.open(#{driver.current_url.to_json},'_blank');")
          driver.close
          driver.switch_to.window driver.window_handles.first
        end
        driver.execute_script("window.innerWidth = #{width}; window.innerHeight = #{height};")
      end

      private

      def build_driver_using(options)
        driver = Selenium::WebDriver.for options.browser, options.browser_options
        #resize_inner_window(driver, *resolution_for(options.agent, options.orientation))
        driver
      end

    end
  end
end
