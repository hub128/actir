require 'test/unit'
require 'watir-webdriver'
require 'selenium-webdriver'
lib = File.dirname(__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actir/config'
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
