module Actir
  module ParallelTests
    module Test
      class Rerunner < Runner

        class << self
          
          #
          # 重新执行失败的测试用例
          #
          # 用例执行通过或者达到了重试次数上限后即返回最终的执行结果
          #
          # 限制:不管是否在同一文件中,用例名称不能重复,即用例名称全局唯一
          #
          # @example : re_run_tests('店铺名称')
          #
          # @param test_result   : [String] 商品名称的字符串
          #
          #        num_processes : [Fixnum] 并发进程数
          #
          #        address       : [String] 执行用例的环境的地址
          #
          #        times         : [Fixnum] 执行次数
          #
          #       process_number : [Fixnum] 暂时无用
          #
          # @return [String] 执行结果字符串
          #
          def re_run_tests(test_result, process_number, num_processes, options, address, times)
              #根据重跑次数重新执行失败用例
              result = re_run(test_result, process_number, num_processes, options, address, times)
              #从老的执行结果输出中提取出相关数据
              old_result = summarize_results(find_results(test_result[:stdout]))
              #puts "old_result : " + old_result
              #从新的执行结果中提取出数据,并算出总数
              #因为若有多个失败用例就有多个执行结果
              new_result = summarize_results(find_results(result[:stdout]))
              #puts "new_result : " + new_result
              #刷新最终的执行结果
              if old_result == nil || old_result == ""
                puts "[Debug] test_result : "
                puts test_result
              end
              if new_result == nil || new_result == ""
                puts "[Debug] result : "
                puts result
              end
              combine_tests_results(old_result, new_result)
          end
          
          private

          def re_run(test_result, process_number, num_processes, options, address, times)
            result = {}
            if times > 0
              #先获取失败用例信息
              tests = capture_failures_tests(test_result)
              cmd = ""
              tests.each do |testcase, testfile|
                #输出一些打印信息
                puts "[ Re_Run ] - [ #{testfile} -n #{testcase} ] - Left #{times-1} times - in Process[#{process_number}]"
                cmd += "#{executable} #{testfile} #{address} -n #{testcase};"
              end 
              #执行cmd,获取执行结果输出
              result = execute_command(cmd, process_number, num_processes, options)
              #先判断是否还是失败，且未满足重试次数
              times -= 1
              if any_test_failed?(result) && times > 0 
                #递归
                result = re_run(result, process_number, num_processes, options, address, times)
              end
            end
            #记录log
            if options[:log]
              log_str = "[re_run_tests]: \n" + result[:stdout]
              Actir::ParallelTests::Test::Logger.log(log_str, process_number)
            end

            #从result中获取执行结果用于生成测试报告
            Actir::ParallelTests::Test::Result.get_testsuite_detail(result, :rerunner)

            return result
          end

          #从输出内容中获取失败用例文件名以及用例名称
          def capture_failures_tests(test_result)
            result_array = test_result[:stdout].split("\n")
            failure_tests_hash = {}
            testcase = ""
            testfile = ""
            result_array.each do |result|
              #取出执行失败的用例文件名称和用例名称
              if (result =~ failure_tests_name_reg) || (result =~ error_tests_name_reg)
                #范例:"testhehe(TestHehe)"
                testcase = $1
              end
              if result =~ failure_tests_file_reg
                #范例:"testcode/test_tt/test_hehe.rb:8:in `xxxx'"
                testfile = $1
              end
              #至于为什么采用testcase => testfile的形式是因为…文件名会重复
              if testcase != "" && testfile != "" 
                failure_tests_hash[testcase] = testfile
                testcase = ""
                testfile = ""
              end
            end
            failure_tests_hash
          end

          #组合出最新的执行结果
          #只需要将老结果中的failure和error的数据替换成新结果中的数据即可
          def combine_tests_results(old_result, new_result)
            if old_result == nil || old_result == ""
              puts "new_result : " + new_result
              raise "old_result is nil" 
            end
            #取出新结果中的failure和error的数据
            new_result =~ failure_error_reg
            failure_error_str = $1
            failure_data      = $2
            error_data        = $3
            #替换老结果中的失败数据
            comb_result = old_result.gsub(failure_error_reg, failure_error_str)
            #按照{:stdout => '', :exit_status => 0}的格式输出内容，不然原有代码不兼容
            #其中exit_status = 0 表示用例全部执行成功,反之则有失败
            exitstatus = ( (failure_data.to_i + error_data.to_i) == 0 ) ? 0 : 1
            {:stdout => comb_result + "\n", :exit_status => exitstatus}
          end

          #判断是否有用例失败
          def any_test_failed?(result)
            Actir::ParallelTests::Test::Result.any_test_failed?(result)
          end

          #获取错误用例名的正则
          def error_tests_name_reg
            Actir::ParallelTests::Test::Result.error_tests_name_reg
          end

          #获取失败用例名的正则
          def failure_tests_name_reg
            Actir::ParallelTests::Test::Result.failure_tests_name_reg
          end

          #获取失败用例文件名的正则
          def failure_tests_file_reg
            /(.+\/test.+rb):\d+:in\s`.+'/
            #/^Loaded\ssuite\s(.+)/
          end

          #获取失败数据的正则
          def failure_error_reg
            /((\d+)\sfailure.*,\s(\d+)\serror)/
          end

        end

      end
    end
  end
end
