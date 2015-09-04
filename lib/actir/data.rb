module Actir

  module Data

    class << self

      def get(key)
        #按照点分割字符串
        key_array = key.split(".")  
        #先取出数组中的第一个元素当做配置文件名称，并从数组中移除此元素
        file_name = key_array.shift
        #再取出第二个元素，指定配置项,并移除
        cfg_name = key_array.shift 
        hash = cfg_name ? load_file(file(file_name))[cfg_name] : load_file(file(file_name))
        #遍历key数组
        until key_array.empty? do
          key = key_array.shift
          hash = hash[key]
        end
        hash
      end

      private 

      def file(file_name)
        File.expand_path(File.join(data_dir, "/#{file_name}.yaml"), __FILE__)
      end

      #默认配置文件夹路径
      def data_dir
        @data_dir ||= File.join($project_path, "data")
      end

      #读取yaml配置文件
      def load_file(file)
        YAML.load_file file
      end

    end

  end

end