module Actir
  class CookiesFile
    class << self

      # 获取cookies文件的路径
      # 因为涉及到权限问题,路径需要放在个人账号目录下
      # 通过whoami命令获取当前账户名称
      # 暂时存放在/User/xx/目录下
      def path
        user_name = `whoami`
        return "/Users/" + user_name + "/"
      end

      def name
        return "cookies.yaml"
      end

      def exists?
        File::exists?(path + name)
      end

    end

  end
end
