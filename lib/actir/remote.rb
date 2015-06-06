require 'actir/config'

module Actir

  #
  # 远程测试环境相关的方法
  #
  # @author: Hub
  #
  # @Date: 2015-3-6 
  #
  module Remote

    #
    # 获取远程selenium测试环境的docker镜像的IPAddress
    #
    # @example : get_remote_address 2
    #
    # @param   : num [Fixnum] selenium-grid 的node镜像的节点数,对应多进程测试时的进程数量  
    #
    # @return  : [Array] IPAddress字符串的数组,形如["127.0.0.1:5555", "127.0.0.2:5555"]
    #
    def self.get_remote_address(num = 0)
      @docker_cfg = Actir::Config.get("config.test_mode.docker") if @docker_cfg == nil
      docker_ip = @docker_cfg["ip"]
      node_sub_name = ( (@docker_cfg["name"] == nil || @docker_cfg["name"] == "") ? "-node" : @docker_cfg["name"])
      docker_node_name = $env + node_sub_name
      docker_inspect_str = "docker inspect -f='{{.NetworkSettings.IPAddress}}' \\`docker ps | grep #{docker_node_name} | grep 5900 | awk '{print \\$11}'\\`"
      #需要判断执行脚本的环境是本地还是Linux服务器,本地需要ssh 
      puts docker_inspect_str if $debug 
      ip_str = if is_local?
        `ssh root@#{docker_ip} "#{docker_inspect_str}"`
      else
        `#{docker_inspect_str}`
      end
      ip_array = ip_str.split("\n")
      address = []
      #如果入参num小于address.size,则返回num个address
      #如果入参num大于address.size,则返回所有address
      #如果入参num为0即默认的不传入参,则返回所有address
      ip_array.each_with_index do |ip, i| 
        address[ip_array.size - 1 -i] = ip + ":" + @docker_cfg["port"]
      end
      if ip_array.size >= num && num != 0
        return address.first(num)
      else
        return address
      end
    end

    # 获取远端docker-selenium的node镜像的个数
    #
    # @example : get_remote_num
    #
    # @return  : [Fixnum] 远端docker-selenium的node镜像的个数
    #
    # def self.get_remote_num 
    #   @docker_cfg = Actir::Config.get("config.test_mode.docker") if @docker_cfg == nil
    #   docker_ip = @docker_cfg["ip"]
    #   node_sub_name = ( (@docker_cfg["name"] == nil || @docker_cfg["name"] == "") ? "-node" : @docker_cfg["name"])
    #   docker_node_name = $env + node_sub_name
    #   #5900是node节点的端口号
    #   docker_inspect_str = "docker ps | grep #{docker_node_name} | grep -c 5900"
    #   num = if is_local?
    #     `ssh root@#{docker_ip} "#{docker_inspect_str}"`
    #   else
    #     `#{docker_inspect_str}`
    #   end
    #   num.to_i
    # end
    
    # 判断执行环境是否是本地环境(Mac)
    def self.is_local?
      hostname = `hostname`
      hostname.include? "local"
    end

  end

end
