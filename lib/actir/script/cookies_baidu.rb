require 'watir-webdriver'

module Actir
  class CookiesBaidu

    class << self

      # 更新百度账号所有的配置文件
      def update_all(address = [])
        baidu_card = Actir::Config.get("cookies.baidu")
        baidu_card.each do |card, value|
          update_cookies(card, address)
        end
      end

      #将所有百度支付卡的available状态恢复为true
      def re_available
        #每次登陆都判断一下cookies文件的上一次修改时间和当前时间
        #如果日期不同，则刷新所有的cookies文件中baidu-card的状态
        unless Actir::Config.is_same_day?("cookies")
          Actir::Config.lock("cookies") do
            str_array = IO.readlines(cookies_file)
            str_array.each_with_index do |line, index|
              if line =~ /available\:\s*false/  
                str_array[index] = line.gsub(/false/, 'true')
              end
            end
            cookiesfile = File.open(cookies_file, 'w')
            str_array.each do |line|
              cookiesfile.puts line
            end
            cookiesfile.close
          end
        end
      end

      # 获取可用的百度账号的hash
      # 返回值{card1 => {"username" => "xxx", "password"=>"iloveyouzan", xxx}}
      def get_useful_card
        # old_config = Actir::Config.config_dir
        # Actir::Config.config_dir = script_config_path
        #通过配置文件判断取出可用的卡的参数
        baidu_card = Actir::Config.get("cookies.baidu")
        card = {}
        baidu_card.each do |key, value|
          if value["available"] == true
            #有可用的卡，取出cookies等参数
            card.store(key, value)
            break
          end
        end
        # Actir::Config.config_dir = old_config
        card
      end

      # 设置不可用的卡
      # 入参传入卡的key
      def set_useless_card(card)
        Actir::Config.set("cookies.baidu." + card + "." + "available", "false")
      end

      # 更新baidu_cookies失败后的清理操作。目前需要手动调用，后续优化
      def clear_after_failure
        @browser.close
      end

      private

      # 更新配置文件中的baidu_cookies
      def update_cookies(card, address = [])
        #打开百付宝
        open_baifubao(address)
        #获取对应卡的账号密码
        args = Actir::Config.get("cookies.baidu." + card)
        #登录百付宝
        login_baifubao(args["username"], args["password"])
        #获取cookies
        cookies = get_baifubao_cookies
        #清除之前的cookies
        modify_cookies(card, cookies)
        puts "Already update baifubao's cookies"
      end

      # 访问百付宝主页
      def open_baifubao(address = [])
        if address.size == 0
          if $mode == :remote
            address = Actir::Remote.get_remote_address(1)
          end
        end
        @browser = Browser.new(:www, :url => address[0], :mode => $mode, :browser => :chrome, :window_size => nil)
        @browser.goto "baifubao.com"
        @browser 
      end

      # 登录百付宝主页
      def login_baifubao(username, password)
        # 选择账号登陆(默认是短信快捷登录，所以需要点击切换一下)
        link_baifubao_login_back.wait_until_present
        link_baifubao_login_back.click
        # 输入账号密码
        text_baifubao_username.wait_until_present
        text_baifubao_username.set username
        text_baifubao_password.set password
        button_baifubao_login.click
      end

      # 获取cookies
      def get_baifubao_cookies
        sleep 5
        id =  @browser.cookies[:BAIDUID][:value]
        ss =  @browser.cookies[:BDUSS][:value]
        @browser.close
        #cookies = "  BAIDUID:\s\s\s\s\s\s\"" + id + "\"\n  BDUSS:\s\s\s\s\s\s\s\s\"" + ss + "\"\n"
        #以hash形式返回
        {:BAIDUID => id, :BDUSS => ss } 
      end

      def modify_cookies(card, cookies)
        cookies.each do |key, value|
          Actir::Config.set("cookies.baidu."+card+"."+key.to_s , "\""+value.to_s+"\"")
        end
      end

      # 配置文件所在文件夹的路径
      def script_config_path
        File.join(File.dirname(__FILE__), "config")
      end

      # 配置文件相对路径
      def cookies_file
        File.join(Actir::Config.config_dir, "/cookies.yaml")
      end

      def text_baifubao_username
        @browser.text_field(:id => 'TANGRAM__PSP_4__userName')
      end

      def text_baifubao_password
        @browser.text_field(:id => 'TANGRAM__PSP_4__password')
      end

      def button_baifubao_login
        @browser.input(:id => 'TANGRAM__PSP_4__submit')
      end

      # 返回账号登陆的按钮
      def link_baifubao_login_back
        @browser.link(:id => 'TANGRAM__PSP_4__sms_btn_back')
      end

    end
  end

end

#Actir::CookiesBaidu.re_available

