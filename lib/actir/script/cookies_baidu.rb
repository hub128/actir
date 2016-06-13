module Actir
  class CookiesBaidu

    class << self

      # cookies文件初始化
      def init
        need_init_cookies = false
        
        #判断文件是否存在
        if file_exists?
          # 读取下配置文件中是否真的有cookies数据，如果没有一样要更新
          cookies = get_cookies("card1")
          # 判断存在的cookies文件是否有规范的cookies内容
          if cookies == nil
            need_init_cookies = true
          else
            if cookies.has_key?(baifubao_BDUSS) && cookies.has_key?(baifubao_STOKEN)
              if cookies[baifubao_BDUSS] == nil || cookies[baifubao_STOKEN] == nil
                need_init_cookies = true
              else
                need_init_cookies = false
              end
            else
              need_init_cookies = true
            end
          end 

        else
          if directory_exists?
            #文件不存在则看目录是否存在
            #目录存在则创建文件
            need_init_cookies = true
          else
            #目录和文件都不存在则创建目录再创建文件
            Dir.mkdir(directory)
            need_init_cookies = true
          end
        end

        if need_init_cookies == true
          file = File.new(directory + file_name, "w")
          file.syswrite(init_content)
          file.close
          # 暂时先只更新一张卡吧
          update_cookies("card1")
        end

      end

      # 更新百度账号所有的配置文件
      def update_all(address = [])
        baidu_card = Actir::Config.get(baifubao_key)
        # 确认目前可用的卡的数目和cookies文件上的是否匹配
        # TODO 先不实现,cookies文件上的cards数量过多目前看不影响
        # baidu_card_cookies = Actir::Config.get("cookies", directory)
        # if baidu_card_cookies != nill && baidu_card != nil
        #   if baidu_card_cookies.size > baidu_card.size
        #
        #   end
        # else
        #   raise "no baifubao cards"
        # end
        baidu_card.each do |card, value|
          update_cookies(card, address)
        end
      end

      #将所有百度支付卡的available状态恢复为true
      def re_available
        #每次登陆都判断一下cookies文件的上一次修改时间和当前时间
        #如果日期不同，则刷新所有的pay文件中baidu-card的状态
        unless Actir::Config.is_same_day?("cookies", directory)
          Actir::Config.lock("pay") do
            str_array = IO.readlines(baifubao_account_file)
            str_array.each_with_index do |line, index|
              if line =~ /available\:\s*false/  
                str_array[index] = line.gsub(/false/, 'true')
              end
            end
            cookiesfile = File.open(baifubao_account_file, 'w')
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
        baidu_card = Actir::Config.get(baifubao_key)
        card = {}
        baidu_card.each do |key, value|
          if value["available"] == true
            # 顺便取一下cookies
            baidu_card_cookies = Actir::Config.get("cookies." + key, directory)
            # value["BAIDUID"] = baidu_card_cookies["BAIDUID"]
            value[baifubao_BDUSS] = baidu_card_cookies[baifubao_BDUSS]
            value[baifubao_STOKEN] = baidu_card_cookies[baifubao_STOKEN]
            #有可用的卡，取出cookies等参数
            card.store(key, value)
            break
          end
        end
        # Actir::Config.config_dir = old_config
        card
      end

      # 设置不可用的卡
      def set_useless_card(card)
        Actir::Config.set(baifubao_key + "." + card + "." + "available", "false")
      end

      # 更新配置文件中的baidu_cookies
      def update_cookies(card, address = [])
        #打开百付宝
        open_baifubao(address)
        #获取对应卡的账号密码
        args = Actir::Config.get(baifubao_key + "." + card)
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
        # @browser.goto "baifubao.com"
        @browser.goto "https://www.baifubao.com/user/0/login/0"
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
        sleep 3
        # id =  @browser.cookies[:BAIDUID][:value]
        ss =  @browser.cookies[baifubao_BDUSS.to_sym][:value]
        stoken =  @browser.cookies[baifubao_STOKEN.to_sym][:value]
        @browser.close
        #cookies = "  BAIDUID:\s\s\s\s\s\s\"" + id + "\"\n  BDUSS:\s\s\s\s\s\s\s\s\"" + ss + "\"\n"
        #以hash形式返回
        # {:BAIDUID => id, :BDUSS => ss } 
        {baifubao_BDUSS.to_sym => ss, baifubao_STOKEN.to_sym => stoken}
      end

      # 更新baidu_cookies失败后的清理操作。目前需要手动调用，后续优化
      def clear_after_failure
        if @browser != nil
          @browser.close
        end
      end

      def modify_cookies(card, cookies)
        cookies.each do |key, value|
          Actir::Config.set("cookies" + "." + card + "." + key.to_s , "\"" + value.to_s + "\"", directory)
        end
      end

      def get_cookies(card)
        Actir::Config.get("cookies" + "." + card, directory)
      end

      def file_exists?
        File::exists?(directory + file_name)
      end

      def directory_exists?
        File::directory?(directory)
      end

      # 获取cookies文件的路径
      # 因为涉及到权限问题,路径需要放在个人账号目录下
      # 通过whoami命令获取当前账户名称
      # 暂时存放在/User/xx/目录下
      def directory
        user_name = `whoami`
        return "/Users/" + user_name.chomp + "/cookies/"
      end

      def file_name
        "cookies.yaml"
      end

      # 百度账号配置文件
      def baifubao_account_file
        File.join(Actir::Config.default_config_dir, "/pay.yaml")
      end

      # 默认的配置文件内容，cookies的key
      def init_content
        "card1:\n" + 
        "  " + baifubao_BDUSS  + ": \n" + 
        "  " + baifubao_STOKEN + ": \n"
      end


      def baifubao_BDUSS
        "BDUSS"
      end

      def baifubao_STOKEN
        "STOKEN"
      end

      def baifubao_key
        "pay.baifubao"
      end

      private

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

