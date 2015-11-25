module Actir
  module ParallelTests
    module Test
      class Result

        class << self
          
          #
          # 通过结果判断测试套的详细信息
          #
          # 将测试套和测试用例的详细信息写入全局变量$testsuites中
          #
          def get_testsuite_detail(test_result, mode = :runner)
            $testsuites = [] unless $testsuites
            if mode == :runner
              get_run_test_info(test_result)
              #如果有用例失败，则记录详细信息，否则不需要
              if any_test_failed?(test_result)
                record_detail(test_result)
              end
            else
              record_detail(test_result)
            end
          end

          def record_detail(test_result)
            failure_detail_hash = get_testfailed_info(test_result)
              $testsuites.each do |testsuite|
                testcases = testsuite[:testcases] 
                testcases.each do |testcase|
                  #标识用例是否执行失败
                  fail_flag = 0
                  failure_detail_hash.each do |testcase_failure, detail|
                    if testcase_failure == testcase[:testcase_name]
                      testcase[:success] = false
                      testcase[:detail] = detail 
                      fail_flag = 1
                      #从hash表中移除 
                      failure_detail_hash.delete(testcase_failure)
                    end
                  end
                  if fail_flag == 0
                    testcase[:success] = true
                    testcase[:detail] = nil
                  end
                end
              end
          end

          def get_run_test_info(test_result)
            output = test_result[:stdout]
            # output.scan(/^(\[suite start\])([^\.]*)(\[suite end\])$/).each do |suite|
            output.scan(file_suite_case_reg).each do |suite|
              filename = suite[0]
              testsuite = suite[1].scan(/^(suitname:\s*)([\d\w]*)/)[0][1]
              testsuite_name = get_unique_testname(filename, testsuite)
              cases = suite[1].scan(/^(testcase:\s*)([\d\w]*)/).inject([]) do |cases,testcase|
                testcase_name = get_unique_testname(filename, testcase[1])
                cases << {:testcase_name => testcase_name, :success => true, :detail => nil}
              end
              # 如果testsuites中已存在此用例的信息，说明这个用例执行了rerun，就不再次添加了
              is_case_exist = $testsuites.inject(false) do |is_case_exist, testsuite|
                if testsuite.has_value?(testsuite_name)
                  is_case_exist = true
                  break
                end
                is_case_exist
              end
              if(is_case_exist == false)
                testsuite = {:testsuite_name => testsuite_name, :testcases =>cases}
                $testsuites << testsuite
              end
            end
          end

          #
          # 通过结果判断失败用例，获取失败用例的详细信息
          #
          # 将测试套和测试用例的详细信息写入全局变量$testsuites中
          #
          def get_testfailed_info(test_result)
            result_array = test_result[:stdout].split("\n")
            failure_detail_hash = {}
            testfile = ""
            testcase = "" 
            detail = ""
            testcase_name = ""
            record_detail_switch = 0

            result_array.each do |result|
              record_detail_switch = 0 if result =~ failure_or_error_switch_off
              #遇到错误信息，开启记录错误信息开关
              record_detail_switch = 1 if result =~failure_or_error_switch_on

              # 记录报错信息
              if record_detail_switch == 1 
                detail += result + "\n"
              end

              # 记录报错用例名称
              if (result =~ failure_tests_name_reg) || (result =~ error_tests_name_reg)
                testcase = $1
              end

              # 记录报错用例文件名称
              if result =~ failure_tests_file_reg
                #范例:"testcode/test_tt/test_hehe.rb:8:in `xxxx'"
                testfile = $1
              end

              # 合并用例名称和文件名称
              testcase_name = get_unique_testname(testfile, testcase)

              if testcase_name != "" && detail != "" && record_detail_switch == 0
                failure_detail_hash[testcase_name] = detail
                testcase = ""
                testfile = ""
                detail = ""
                testcase_name = ""
              end
            end

            failure_detail_hash
          end

          # 从执行结果中获取文件/测试套/测试用例的名称
          def file_suite_case_reg
            /^Loaded\ssuite\s(.*)\nStarted\n\[suite start\]([^\.]*)\[suite end\]$/
          end

          #判断是否有用例失败
          def any_test_failed?(result)
            result[:exit_status] != 0
          end

          #获取错误用例名的正则
          def error_tests_name_reg
            /^Error:\s(test.+)\(.+\):/
          end

          #获取失败用例名的正则
          def failure_tests_name_reg
            /^Failure:\s(test.+)\(.+\)/
          end

          # 获取失败用例文件名的正则
          def failure_tests_file_reg
            /(.+\/test.+rb):\d+:in\s`.+'/
          end

          # 测试套信息开头正则
          def test_info_swtich_on
            /^\[suite start\]/
          end

          # 测试套信息截止正则
          def test_info_swtich_off
            /^\[suite end\]/
          end

          # 测试用例执行报错信息开头正则
          def failure_or_error_switch_on
            /^Failure:|^Error:/
          end

          # 测试用例执行报错信息截止正则
          def failure_or_error_switch_off
            /^===============================================================================$/
          end

          # 因为测试用例名称/测试套名称有可能重复，所以采用 测试文件名称:测试用例名称 的方式作为测试用例名称的唯一标识
          # 也可用于测试套名称组合
          def get_unique_testname(testfile, test)
            if (test != "" || test != nil) && (testfile != "" || testfile != nil)
              # 判断测试文件名称是否包含.rb后缀，如果没有则加上
              unless testfile =~ /.*\.rb$/
                testfile += ".rb"
              end
              return testfile + ":" + test 
            else
              return ""
            end
          end

          def get_testfile_from_unique(unique_testname)
            unique_testname =~ /(.*)\:(.*)/
            $1       
          end

          def get_testcase_from_unique(unique_testname)
            unique_testname =~ /(.*)\:(.*)/
            $2        
          end

        end

      end
    end
  end
end
