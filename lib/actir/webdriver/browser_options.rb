require 'facets/hash/except'

module Actir
  module Webdriver
    class BrowserOptions

      def initialize(opts, user_agent_string)
        @options = opts
        options[:browser] ||= :chrome
        options[:agent] ||= :iphone
        #options[:orientation] ||= :portrait
        initialize_for_browser(user_agent_string)
      end

      def method_missing(*args, &block)
        m = args.first
        value = options[m]
        super unless value
        value.downcase
      end

      def browser_options
        #options.except(:browser, :agent, :orientation)
        options.except(:browser, :agent)
      end

      private

      def options
        @options ||= {}
      end

      def initialize_for_browser(user_agent_string)
        case options[:browser]
        when :firefox
          options[:profile] ||= Selenium::WebDriver::Firefox::Profile.new
          options[:profile]['general.useragent.override'] = user_agent_string
        when :chrome
          options[:switches] ||= []
          options[:switches] << "--user-agent=#{user_agent_string}"
        # add bu Hub
        # support phantomjs
        when :phantomjs
          options[:desired_capabilities] ||= Selenium::WebDriver::Remote::Capabilities.phantomjs(
            "phantomjs.page.settings.userAgent" => user_agent_string
          )
        else
          raise "WebDriver currently only supports :chrome, :firefox and :phantomjs"
        end
        
      end
    end
  end
end
