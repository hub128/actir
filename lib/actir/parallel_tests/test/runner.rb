module Actir
  module ParallelTests
    module Test
      class Runner
        NAME = 'Test'

        class << self
          # --- usually overwritten by other runners

          def name
            NAME
          end
          
          # modify by Hub
          # 修改正则表达式使得使用我们目前的测试脚本文件命名 : test_xxx.rb
          def test_suffix
           # /_(test|spec).rb$/
           /test.*\.rb$/
          end

          def test_file_name
            "test"
          end

          # modify by Hub 
          # add param address to ruby script as ARGV[0]
          # modify cmd to exec ruby test script 
          def run_tests(test_files, process_number, num_processes, options, address)
            #require_list = test_files.map { |file| file.sub(" ", "\\ ") }.join(" ")
            #cmd = "#{executable} -Itest -e '%w[#{require_list}].each { |f| require %{./\#{f}}}' #{address}"
            #execute_command(cmd, process_number, num_processes, options)
            cmd = ""
            test_files.each do |file|
              cmd += "#{executable} #{file} #{address};"
            end 
            cmd += "\n"
            result = execute_command(cmd, process_number, num_processes, options)
            #记录log
            if options[:log]
              log_str = "[run_tests]: \n" + result[:stdout]
              Actir::ParallelTests::Test::Logger.log(log_str, process_number)
            end
            result
          end

          def line_is_result?(line)
            line.gsub!(/[.F*]/,'')
            line =~ /\d+ failure/
          end

          # --- usually used by other runners

          # finds all tests and partitions them into groups
          def tests_in_groups(tests, num_groups, options={})
            tests = find_tests(tests, options)

            case options[:group_by]
            when :found
              tests.map! { |t| [t, 1] }
            when :filesize
              sort_by_filesize(tests)
            when nil
              sort_by_filesize(tests)
            else
              raise ArgumentError, "Unsupported option #{options[:group_by]}"
            end

            Grouper.in_even_groups_by_size(tests, num_groups, options)
          end

          def execute_command(cmd, process_number, num_processes, options)
            env = (options[:env] || {}).merge(
              #"TEST_ENV_NUMBER" => test_env_number(process_number),
              "TEST_ENV_NUMBER" => process_number,
              "PARALLEL_TEST_GROUPS" => num_processes
            )
            cmd = "nice #{cmd}" if options[:nice]
            cmd = "#{cmd} 2>&1" if options[:combine_stderr]
            puts cmd if options[:verbose]

            execute_command_and_capture_output(env, cmd, options[:serialize_stdout])
          end

          def execute_command_and_capture_output(env, cmd, silence)
            # make processes descriptive / visible in ps -ef
            separator = ';'
            exports = env.map do |k,v|
              "export #{k}=#{v}"
            end.join(separator)
            cmd = "#{exports}#{separator}#{cmd}"
            output = open("|#{cmd}", "r") { |output| capture_output(output, silence) }

            #modify by shanmao
            #获取执行的测试套详细信息
            get_testsuite_detail(output)
            #获取失败的用例的详情
            get_testfailed_detail(output)

            #modify by Hub
            #exitstatus = $?.exitstatus
            #"$?.exitstatus" 返回的值有时有问题，不能明确标示用例执行结果是否成功
            #改成判断结果数据中是否有failure和error
            exitstatus = get_test_failed_num(find_results(output).join)
            {:stdout => output, :exit_status => exitstatus}
          end

          def find_results(test_output)
            test_output.split("\n").map {|line|
              line.gsub!(/\e\[\d+m/,'')
              next unless line_is_result?(line)
              line
            }.compact
          end

          def test_env_number(process_number)
            process_number == 0 ? '' : process_number + 1
          end

          def summarize_results(results)
            sums = sum_up_results(results)
            sums.to_a.map{|word, number|  "#{number} #{word}#{'s' if number != 1}" }.join(', ')
            #sums.sort.map{|word, number|  "#{number} #{word}#{'s' if number != 1}" }.join(', ')
          end

          protected

          def executable
            ENV['PARALLEL_TESTS_EXECUTABLE'] || determine_executable
          end

          def determine_executable
            if Actir::Remote.is_local?
              "ruby"
            else
              #TO-DO jenkins服务器上的ruby是用rvm管理的,这里有个坑，在jenkins中调用ruby命令会报找不到
              #后续考虑更换rvm至rbenv
              #jenkins服务器上的ruby所在地址
              "/usr/local/rvm/rubies/ruby-2.0.0-p598/bin/ruby"
            end
          end
          
          #
          # 通过结果判断测试套的详细信息
          # 将测试套和测试用例的详细信息写入全局变量$testsuites中
          #
          def get_testsuite_detail output
            $testsuites = [] unless $testsuites
            output.scan(/^(\[suite start\])([^\.][^E]*)(\[suite end\])$/).each do |suite|
              suitename = suite[1].scan(/^(suitname:\s*)([\d\w]*)/)[0][1]
              cases = suite[1].scan(/^(testcase:\s*)([\d\w]*)/).inject([]) do |cases,testcase|
                cases << {:testcase_name => testcase[1], :succuss => true, :detail => nil}
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
            # p $testsuites
          end

          #
          # 通过结果判断失败用例，获取失败用例的详细信息
          # 将测试套和测试用例的详细信息写入全局变量$testsuites中
          #
          def get_testfailed_detail output

          end

          #
          # 通过结果判断是否有用例失败
          # 返回失败用例的数目 
          #
          def get_test_failed_num(result)
            #获取结果字符串中的failure和error用例数
            failed_num = 0
            result.scan(/(\d+)\s(failure|error)/).each do |failed|
              failed_num += failed[0].to_i
            end
            failed_num
          end

          def sum_up_results(results)
            results = results.join(' ').gsub(/s\b/,'') # combine and singularize results
            #results = results.join(' ')
            counts = results.scan(/(\d+) (\w+)/)
            counts.inject(Hash.new(0)) do |sum, (number, word)|
              sum[word] += number.to_i
              sum
            end
          end

          # read output of the process and print it in chunks
          def capture_output(out, silence)
            result = ""
            loop do
              begin
                read = out.readpartial(1000000) # read whatever chunk we can get
                if Encoding.default_internal
                  read = read.force_encoding(Encoding.default_internal)
                end
                result << read
                unless silence
                  $stdout.print read
                  $stdout.flush
                end
              end
            end rescue EOFError
            result
          end

          def sort_by_filesize(tests)
            tests.sort!
            tests.map! { |test| [test, File.stat(test).size] }
          end

          # modify by Hub
          # 由原来的包含路径的文件名直接进行正则匹配改为取出文件的文件名进行匹配,更准确,不受文件夹命名的影响
          def find_tests(tests, options = {})
            (tests || []).map do |file_or_folder|
              if File.directory?(file_or_folder)
                #取出文件和文件夹名字
                files_and_folder = files_in_folder(file_or_folder, options)
                #去掉文件夹名字
                files = files_and_folder.grep(test_suffix)
                #去掉不以test开头的测试脚本
                files_2_delete = Array.new
                files.each do |file|
                  file_name = File.basename(file)
                  #不能在遍历数组时进行delete操作
                  #记录要删除的元素名称
                  files_2_delete << file unless file_name =~ /^test.*\.rb$/
                  #files.delete(file) unless file_name =~ /^test.*\.rb$/
                end
                files_2_delete.each { |file_2_delete| files.delete(file_2_delete) }
                files
              else
                file_or_folder
              end
            end.flatten.uniq
          end

          # modify by Hub
          # Bug Fix
          # lack of method 'glob'
          def files_in_folder(folder, options={})
            pattern = "**{,/*/**}/*"
            # modify by Hub
            # add method glod : Dir.glob
            #Dir[File.join(folder, pattern)].uniq
            Dir.glob(File.join(folder, pattern)).uniq
          end

        end
      end
    end
  end
end
