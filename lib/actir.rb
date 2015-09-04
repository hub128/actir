require 'test/unit'
require 'watir-webdriver'
require 'selenium-webdriver'
lib = File.dirname(__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actir/config'
require 'actir/data'
require 'actir/initializer'
require 'actir/remote'
require 'actir/basic_page'
require 'actir/parallel_tests/parallel_tests'
require 'actir/webdriver/browser'
require 'actir/script/cookies_baidu'
require 'actir/version'

module Actir
  
  #测试用例基础类，读取配置文件定义常量
  class TestCase < Test::Unit::TestCase
    class << self
      # $testsuites = []
      def startup
        # 执行用例前，将测试套名字和用例名输出
        suite_name = self.to_s
        if (suite_name != "Actir::TestCase" && suite_name != "BaseTest")
          puts "[suite start]"
          puts "suitname: #{suite_name}\n"
          test_methods = instance_methods.grep(/^test_/).map {|case_name|case_name.to_s}
          test_methods.each do |testcase|
            puts "testcase: #{testcase}\n"
          end
          puts "[suite end]"
        end
      end
    end

    #IP地址的正则表达式
    num = /\d|[01]?\d\d|2[0-4]\d|25[0-5]/  
    ip = /^(#{num}\.){3}#{num}/ 
    #遍历所有的入参，取出IP作为传给测试脚本的IPAddress
    ARGV.each do |arg| 
      if arg =~ ip
        $address = arg
      end
    end

    #若用例执行失败则进行截图，在每个用例的teardown方法中直接调用，传入浏览器对象实例
    def screenshot_if_failed(browser)
      unless self.passed?
        Dir::mkdir('screenshots') if not File.directory?('screenshots')
        time = Time.now.strftime('%Y%m%d-%H%M%S')
        screenshot = "./screenshots/FAILED_#{self.name}_#{time}.png"
        browser.screenshot.save screenshot
      end
    end
  end
  
end
