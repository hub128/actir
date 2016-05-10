require "parallel"
require 'actir/parallel_tests/cli'
require 'actir/parallel_tests/grouper'

module Actir
  module ParallelTests
    
    autoload :CLI, "cli"
    autoload :Grouper, "grouper"
          
    # 一些通用类方法
    class << self
      #判断执行的进程数
      def determine_number_of_processes(count)
        [
          count,
          #ENV["PARALLEL_TEST_PROCESSORS"],
          #核数
          #Parallel.processor_count
          #count数不填模式为1
          1
        ].detect{|c| not c.to_s.strip.empty? }.to_i
      end

      #判断失败用例重新执行的次数
      def determine_times_of_rerun(times)
        [
          times,
          0
        ].detect{|c| not c.to_s.strip.empty? }.to_i
      end

      #判断用例执行的环境是local还是remote
      def determine_run_mode(mode)
        env_mode = :local
        #判断是否存在config.yaml配置文件，如果不存在，则test_mode给默认值
        if File.exist?(File.join($project_path, "config", "config.yaml")) 
          #刷新配置文件中的env配置项为remote模式，以防止本地调试代码改写上传后导致CI失败
          if mode
            unless mode == /#{Actir::Config.get("config.test_mode.mode")}/
              #同步修改配置文件，需要先将Symbol转换成String
              mode_str = ":" + mode.to_s
              Actir::Config.set("config.test_mode.mode", mode_str)
            end
            env_mode = mode
          else
            env_mode = Actir::Config.get("config.test_mode.mode")
          end
        else
          if mode
            env_mode = mode
          end
        end
        ENV["mode"] = env_mode.to_s
        env_mode
      end

      # real time even if someone messed with timecop in tests
      def now
        if Time.respond_to?(:now_without_mock_time) # Timecop
          Time.now_without_mock_time
        else
          Time.now
        end
      end

      def delta
        before = now.to_f
        yield
        now.to_f - before
      end
    
    end

  end
end
