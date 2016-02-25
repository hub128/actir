require 'actir/webdriver/driver'

#
# 初始化测试用浏览器
#
# @author: Hub
#
# @Date: 2015-1-5 
#
class Browser

  attr_reader :browser

  PHANTOMJS_SIZE = {'width' => 1334, 'height' => 750}
  REMOTE_SIZE    = {'width' => 1050, 'height' => 611}

  #
  # 初始化函数
  #
  # 可以配置测试的mode：
  #  1.:env
  #     :local  本地环境上测试
  #     :remote 远程测试环境上测试
  #  2.:browser
  #     :chrome
  #     :firefox 
  #  3.:agent wap页面的useragent类型 
  #     :iphone
  #     :android_phone
  #  4.:address  当env为:remote时，url指定远程执行脚本的地址
  #
  def initialize(type = :www, *args)
    args = init_args(*args)
    @browser_type = args[:browser]
    @agent = args[:agent]
    @env = args[:mode]
    @window_size = args[:window_size]
    if @env == :remote
      @url = if args[:url]
        "http://#{args[:url]}/wd/hub"
      else
        #TO-DO ,远程模式没有传入IP,改成local模式
        @env = :local
        puts "selenium-node's IPAddress is null. switch to local mode"
      end
    end
    if type == :www
      @watir_browser = browser_www
    elsif type == :wap
      @watir_browser = browser_wap
    else
      raise "error browser type , please send args with :www or :wap!"
    end
    define_page_method
  end

  def goto(uri)
    hasLoaded = 0
    for i in 1..3
      begin 
      Timeout::timeout(10)  do
        # puts "Time #{i}"
        super(uri)

        if self.execute_script("return document.readyState;") == "complete"
          # puts "has completed"
          hasLoaded = 1
          break
        end
      end
      rescue Timeout::Error => e
        puts "Page load timed out: #{e}"
      end

      if hasLoaded == 1
        break
      end
      sleep(0.05)
    end
  end

  # 初始化入参
  def init_args(args = {})
    config_exist = File.exist?(config_file)
    unless args.has_key?(:mode)
      #若通过actir执行测试用例，则会配置ENV的模式
      if ENV["mode"]
        args[:mode] = ENV["mode"].to_sym
      else
        #若ENV为空，则读取配置文件，判断有无配置文件
        if config_exist
          env = $config["config"]["test_mode"]["env"]
          args[:mode] = (env == nil) ? :local : env
        else
          args[:mode] = :local
        end
      end
    end
    unless args.has_key?(:browser)
      if config_exist 
        browser_type = $config["config"]["test_mode"]["browser"]
        args[:browser] = (browser_type == nil) ? :chrome : browser_type
      else
        args[:browser] = :chrome
      end
    end
    unless args.has_key?(:window_size)
      if config_exist
        window_size = $config["config"]["window_size"]
        if window_size != nil
          width = window_size["width"]
          height = window_size["height"]
        end
        args[:window_size] = (width == nil || height == nil) ? nil : window_size
      else
        args[:window_size] = nil
      end
    end
    args[:agent] = :iphone  unless args.has_key?(:agent)
    args[:url] = $address  unless args.has_key?(:url)
    args
  end


  #
  # 打开普通www浏览器
  #
  def browser_www
    case @env
    when :local
      #本地chrome浏览器
      browser = Watir::Browser.new @browser_type
    when :remote
      #远程服务器的chrome浏览器
      browser = Watir::Browser.new(
        :remote, 
        :desired_capabilities => @browser_type, 
        :url => @url
      )
    end
    #重新设置窗口大小,不然phantomjs的ghost driver各种问题
    if @browser_type == :phantomjs
      browser.window.resize_to(PHANTOMJS_SIZE["width"], PHANTOMJS_SIZE["height"])
    elsif @env == :remote
      browser.window.resize_to(REMOTE_SIZE["width"], REMOTE_SIZE["height"])
    elsif @window_size != nil
      browser.window.resize_to(@window_size["width"], @window_size["height"])
    end
    browser
  end

  #
  # 通过useragent打开WAP页面
  #
  # local模式下直接打开本地chrome浏览器,或者使用phantomjs无界面执行
  #
  # remote模式下通过设置chrome的switches参数远程打开测试环境上的chrome浏览器
  #
  # TO-DO: remote模式的phantomjs
  #
  def browser_wap
    case @env
    when :local
      driver = Actir::Webdriver.driver(:browser => @browser_type, :agent => @agent)
    when :remote
      driver = Actir::Webdriver.driver(:browser => @browser_type, :agent => @agent, :url => @url)
    end
    browser = Watir::Browser.new driver
    if @browser_type == :phantomjs
      #重新设置窗口大小,不然phantomjs的ghost driver各种问题 = =
      browser.window.resize_to(PHANTOMJS_SIZE["width"], PHANTOMJS_SIZE["height"])
    end
    browser
  end
  
  # 自动定义驱动需要调用的所有元素相关的方法
  # 需要所有的页面元素相关的类名以XXXPage方式命名
  def define_page_method
    p Module.constants.grep(/(Page|Wap)$/) if $debug
    Module.constants.grep(/(Page|Wap)$/).each do |page_klass|
      if basic_page?(page_klass)
        method = ""
        if page_klass.to_s =~ /Page$/
          method_name = page_klass.to_s.gsub!(/Page$/, "_page")
        elsif page_klass.to_s =~ /Wap$/
          method_name = page_klass.to_s.gsub!(/Wap$/, "_wap")
        end
        self.class.send :define_method, "#{method_name.downcase}" do
          page = Module.const_get(page_klass).new(@watir_browser)
          page
        end #define_method
        puts "defined #{method_name.downcase}" if $debug
      end #if
    end #each
  end

  def valid_page_klass? klass
    return false if klass.eql?(:Page)
    return false if klass.eql?(:BasicPage)
    Module.const_get(klass) < Actir::BasicPage
  end
  alias_method :basic_page?, :valid_page_klass?

  def method_missing(m, *args, &blk)
    if @watir_browser.respond_to? m
      @watir_browser.send(m, *args, &blk)
    else
      super
    end #if
  end

  #
  # 在同一个浏览器的新tab页上打开指定url的页面,并自动将焦点放到新开窗口中
  #
  # @example : 
  #    browser.new_window('youzan.com') do
  #      action
  #    end
  #
  # @param url : [String] url字符串
  # 
  def new_window url
    @watir_browser.execute_script("window.open(\"#{url}\")")
    #获取浏览器中的窗口数目
    window_num = @watir_browser.windows.length
    #默认要操作的新窗口都是最后一个窗口
    @watir_browser.windows[window_num - 1].use do  
      #重新设置窗口大小,不然phantomjs的ghost driver各种问题 = =
      if @browser_type == :phantomjs
        @watir_browser.window.resize_to(PHANTOMJS_SIZE["width"],PHANTOMJS_SIZE["height"])
      end
      #使用执行块，由调用者决定在新开的订单详情页面内做些啥
      yield
    end
  end

  private

  def config_file
    File.join($project_path, "config", "config.yaml")
  end

end

