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
            end
            
            #如果有用例失败，则记录详细信息，否则不需要
            if any_test_failed?(test_result)
              failure_detail_hash = get_testfailed_detail(test_result)
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
          end

          def get_run_test_info(test_result)
            output = test_result[:stdout]
            output.scan(/^(\[suite start\])([^\.]*)(\[suite end\])$/).each do |suite|
              suitename = suite[1].scan(/^(suitname:\s*)([\d\w]*)/)[0][1]
              cases = suite[1].scan(/^(testcase:\s*)([\d\w]*)/).inject([]) do |cases,testcase|
                cases << {:testcase_name => testcase[1], :success => true, :detail => nil}
              end
              # 如果testsuites中已存在此用例的信息，说明这个用例执行了rerun，就不再次添加了
              is_case_exist = $testsuites.inject(false) do |is_case_exist, testsuite|
                if testsuite.has_value?(suitename)
                  is_case_exist = true
                  break
                end
                is_case_exist
              end
              if(is_case_exist == false)
                testsuite = {:testsuite_name => suitename, :testcases =>cases}
                $testsuites << testsuite
              end
            end
          end

          #
          # 通过结果判断失败用例，获取失败用例的详细信息
          #
          # 将测试套和测试用例的详细信息写入全局变量$testsuites中
          #
          def get_testfailed_detail(test_result)
            result_array = test_result[:stdout].split("\n")
            failure_detail_hash = {}
            testcase = "" 
            detail = ""
            record_detail_switch = 0

            result_array.each do |result|
              record_detail_switch = 0 if result =~ failure_or_error_switch_off
              #遇到错误信息，开启记录错误信息开关
              record_detail_switch = 1 if result =~failure_or_error_switch_on

              if record_detail_switch == 1 
                detail += result + "\n"
              end

              if (result =~ failure_tests_name_reg) || (result =~ error_tests_name_reg)
                testcase = $1
              end

              if testcase != "" && detail != "" && record_detail_switch == 0
                failure_detail_hash[testcase] = detail
                testcase = ""
                detail = ""
              end
            end

            failure_detail_hash
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

          def test_info_swtich_on
            /^\[suite start\]/
          end

          def test_info_swtich_off
            /^\[suite end\]/
          end

          def failure_or_error_switch_on
            /^Failure:|^Error:/
          end

          def failure_or_error_switch_off
            /^===============================================================================$/
          end


        end

      end
    end
  end
end
