require 'actir/parallel_tests/test/runner'

module Actir
  module ParallelTests
    module Test
      class Logger

        #为每个进程准备一个变量表示是否需要初始化log文件，暂时先定10个
        @@prepared = []
        #不知道为什么代码中export ENV无效，暂时先用10
        #num = ENV["PARALLEL_TEST_GROUPS"].to_i
        for i in 1..10
          @@prepared << false
        end

        class << self 

          def log(result, process_index)
            #获取执行环境的当前进程号以及总进程数目
            #process_index = env["TEST_ENV_NUMBER"]
            #num_process   = env["PARALLEL_TEST_GROUPS"]
            prepare(process_index)

            lock(process_index) do
              File.open(logfile(process_index), 'a') { |f| f.puts result }
            end
          end

          # 打印每个进程的log文件内容到屏幕上
          def show_log(process_index)
            separator = "\n"
            File.read(logfile(process_index)).split(separator).map do |line| 
              if line == ""
                puts line 
              else
                puts "[process_" + process_index.to_s + "] - " + line 
              end
            end
          end

          private

          # ensure folder exists + clean out previous log
          # this will happen in multiple processes, but should be roughly at the same time
          # so there should be no log message lost
          def prepare(process_index)
            return if @@prepared[process_index]
            @@prepared[process_index] = true
            FileUtils.mkdir_p(File.dirname(logfile(process_index)))
            File.write(logfile(process_index), '')
          end

          def lock(process_index)
            File.open(logfile(process_index), 'r') do |f|
              begin
                f.flock File::LOCK_EX
                yield
              ensure
                f.flock File::LOCK_UN
              end
            end
          end

          def logfile(process_index)
            "tmp/parallel_test_p_#{process_index}.log"
          end

        end

      end
    end
  end
end

