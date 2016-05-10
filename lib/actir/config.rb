require 'yaml'
require 'ostruct'

module Actir

  #
  # 读取yaml文件中配置的内容
  #
  # @author: Hub
  #
  # @Date: 2015-1-20
  #
  module Config
    
    class << self

      attr_accessor :default_config_dir
      
      #
      # 从yaml文件中读取youzan的cookies
      #
      # @example : youzan_cookies
      #
      # @return [Hash] youzan的cookies的hash
      #
      # def youzan_cookies(youzan_user)
      #   cfg_str = "cookies." + youzan_user
      #   get(cfg_str)
      # end
      
      #
      # 从yaml文件中读取出所有内容
      #
      # @example : get_content(path)
      #
      # @return [OpenStruct] 所有配置文件内容 
      #
      def get_content(filepath)
        f ||= filepath if valid?(filepath)
        File.open(f) {|handle| @hash_content = YAML.load(handle)}
        if (is_multi_env_cfg?(@hash_content))
          @hash_content = @hash_content[ENV["env"]]
        end
        content = OpenStruct.new(@hash_content)
        content
      end

      #
      # 从config文件夹下的配置文件中读取对应的配置项，以hash形式返回
      #
      # @example : get "safeguard.mode"
      #
      # @param [String] : 指定配置项的字符串,形如safeguard.safeguard_type，以点衔接
      #              
      #                   第一个字符串表示配置文件的名字，之后表示在该文件中的配置项名称     
      #
      # @return [Hash] 对应配置项的hash
      #
      def get(key, config_path = nil)
        #按照点分割字符串
        key_array = key.split(".")  
        #先取出数组中的第一个元素当做配置文件名称，并从数组中移除此元素
        file_name = key_array.shift
        #再取出第二个元素，指定配置项,并移除
        # cfg_name = key_array.shift 
        hash = {}
        #加载yaml配置文件，加锁
        lock(file_name, config_path) do
          # hash = cfg_name ? load_file(file(file_name, config_path))[cfg_name] : load_file(file(file_name, config_path))
          hash = load_file(file(file_name, config_path))
        end
        #判断是否存在 online 和 qatest 关键词，存在的话就读取当前env配置
        if (is_multi_env_cfg?(hash))
          #在key_array头上加入env配置
          key_array.unshift(determine_env)
        end
        #遍历key数组
        until key_array.empty? do
          key = key_array.shift
          hash = hash[key]
        end
        hash
      end

      #
      # 更新配置文件中的key对应的value值
      #
      # 改文件加锁，解决多进程同时写文件的问题
      #
      # @example : set("config.test_mode.mode", ":remote")
      #
      # @param key   : [String] 指定配置项的字符串,形如config.test_mode.mode，以点衔接
      #              
      #        value : [String] 要修改的值的字符串     
      #
      def set(key, value, config_path = nil)
        #按照点分割字符串
        key_array = key.split(".")  
        #先取出数组中的第一个元素当做配置文件名称，并从数组中移除此元素
        file_name = key_array.shift

        hash = {}
        #加载yaml配置文件，加锁
        lock(file_name, config_path) do
          # hash = cfg_name ? load_file(file(file_name, config_path))[cfg_name] : load_file(file(file_name, config_path))
          hash = load_file(file(file_name, config_path))
        end
        #判断是否存在 online 和 qatest 关键词，存在的话就读取当前env配置
        if (is_multi_env_cfg?(hash))
          #在key_array头上加入env配置
          key_array.unshift(determine_env)
        end

        cfg_str = key_array.shift
        old_value = ""
        lock(file_name, config_path) do
          #先读出所有的内容
          str_array = IO.readlines(file(file_name, config_path))
          str_array.each_with_index do |line, index|
            if ( cfg_str != "" && line =~ /(\s*#{cfg_str}\:\s*)(.*)/ )
              cfg_key = $1
              old_value = $2
              #找对了父节点，继续取下一个
              if key_array.size > 0
                cfg_str = key_array.shift
              else
                #只剩最后一个配置项了，说明找到了唯一的配置项，修改之
                replace_str = cfg_key.chomp + value
                str_array[index] = replace_str
                cfg_str = ""
              end
            end
          end
          config_file = File.open(file(file_name, config_path), "w")
          str_array.each do |line|
            config_file.puts line
          end
          config_file.close
        end
        puts "set [" + key + "]'s value form " + old_value + " into " + value
      end


      #
      # 判断配置文件的上一次修改时间和当前时间是否一样
      #
      # @example : is_same_day?("config")
      #
      # @param file_name : [String] 配置文件的名字,后缀省略
      #               
      # @return : [Boolean] 同一天则返回true
      #
      #                     不同则返回false
      #
      def is_same_day?(file_name, config_path = nil)
        now_date = Time.new.strftime("%m-%d")
        modify_date = get_modify_time(file_name, config_path)
        now_date == modify_date
      end

      #获取配置文件的修改时间(只精确到日期，不考虑具体时间)
      #返回String,格式为：04-27... 12-29
      def get_modify_time(file_name, config_path = nil)
        sh_str = "ls -l " + file(file_name, config_path) + " | awk '{print $6 \"-\" $7}'"
        stat_str = `#{sh_str}`  
        #从中取出月份和日期
        stat_str =~ /(\d+).*\-(\d+)/
        month = $1
        day = $2
        #若果是1-9,则在前面加个0
        if month == "" || day == "" || month == nil || day == nil
          return ""
        else
          month = "0" + month if month.to_i <= 9 && month.to_i >= 1
          day = "0" + day if day.to_i <= 9 && day.to_i >= 1
          month + "-" + day
        end
      end
      
      # 多进程操作文件时加锁
      def lock(file_name, config_path = nil)
        File.open(file(file_name, config_path), 'r') do |f|
          begin
            f.flock File::LOCK_EX
            yield
          ensure
            f.flock File::LOCK_UN
          end
        end
      end

      #配置文件路径
      def file(file_name, config_path = nil)
        config_dir = (config_path == nil) ? default_config_dir : config_path
        File.expand_path(File.join(config_dir, "/#{file_name}.yaml"), __FILE__)
      end
      
      #默认配置文件夹路径
      def default_config_dir
        @default_config_dir ||= File.join($project_path, "config")
      end
      
      private

      #读取yaml配置文件
      def load_file(file)
        YAML.load_file file
      end

      def valid?(filepath)
        raise "file didn't exist!" unless File.exists?(filepath)
        true
      end

      # 判断执行环境，如果$env为nil则从环境变量里面读取
      def determine_env
        if $env
          $env
        else
          ENV["env"]
        end
      end

      # 判断是否是多环境配置文件
      def is_multi_env_cfg?(hash)
        hash.has_key?("online") || hash.has_key?("qatest")
      end

    end
  end
end

#Actir::Config.set("cookies.baidu.card2.available", "false")
#puts Actir::Config.is_same_day?("cookies")