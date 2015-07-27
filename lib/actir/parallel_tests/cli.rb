require 'optparse'
require 'tempfile'
require 'actir'
require 'actir/parallel_tests/report/html_reporter'

module Actir
  module ParallelTests

    class CLI
      def run(argv)
        $env = "online"
        options = parse_options!(argv)
        num_processes = Actir::ParallelTests.determine_number_of_processes(options[:count])
        $mode = Actir::ParallelTests.determine_run_env(options[:mode])
        if options[:execute]
          execute_shell_command_in_parallel(options[:execute], num_processes, options)
        else
          run_tests_in_parallel(num_processes, options)
        end
      end

      private

      def execute_in_parallel(items, num_processes, options)
        Tempfile.open 'parallel_tests-lock' do |lock|
          return Parallel.map(items, :in_threads => num_processes) do |item|
            result = yield(item)
            report_output(result, lock) if options[:serialize_stdout]
            result
          end
        end
      end

      def run_tests_in_parallel(num_processes, options)
        test_results = nil
        
        #修改全局变量$env至对应的预发布环境的名字
        if options[:pre_name] 
          # 不等于当前的预发环境
          if options[:pre_name] != $env
            $env = options[:pre_name]
          end
        else
          if options[:pre_name] != $env
            $env = "online"
          end
        end

        report_time_taken do
          groups = @runner.tests_in_groups(options[:files], num_processes, options)

          # @modify by Hub
          # @Date : 2015.3.9
          # 远程执行模式下获取服务器IP和端口号
          address = []
          if $mode == :remote
            address = Actir::Remote.get_remote_address(num_processes)
            num_processes = address.size
          end

          #更新百度支付-百付宝的cookies
          if options[:update]
            Actir::CookiesBaidu.update_all
          end

          #计算重跑次数
          re_run_times = Actir::ParallelTests.determine_times_of_rerun(options[:rerun])
          #报用例数
          report_number_of_tests(groups)
          #报执行环境
          report_address_of_env(address)
          #并发执行不同group中的测试用例
          test_results = execute_in_parallel(groups, groups.size, options) do |group|
            p_num = groups.index(group)
            #执行用例脚本
            result = run_tests(group, p_num, num_processes, options, address[p_num])
            #从结果中取出失败用例重跑
            if ( result[:exit_status] != 0 ) && ( re_run_times > 0 )
              result = Actir::ParallelTests::Test::Rerun.re_run_tests(result, p_num, num_processes, options, address[p_num], re_run_times)
            end
            result
          end

          #顺序输出并发执行过程
          show_process_serialize(num_processes, options)

          #输出最终的执行结果
          report_results(test_results, options)
        end

        abort final_fail_message if any_test_failed?(test_results)
      end

      def run_tests(group, process_number, num_processes, options, address)
        if group.empty?
          {:stdout => '', :exit_status => 0}
        else
          #puts pre_str + "ready to exec #{group}"
          @runner.run_tests(group, process_number, num_processes, options, address)
        end
      end

      def report_output(result, lock)
        lock.flock File::LOCK_EX
        $stdout.puts result[:stdout]
        $stdout.flush
      ensure
        lock.flock File::LOCK_UN
      end

      def report_results(test_results, options)
        results = @runner.find_results(test_results.map { |result| result[:stdout] }*"")
        puts division_str
        puts pre_str + @runner.summarize_results(results)

        #add by shanmao
        #生成详细报告
        detail_report if (options[:report] == true)
        #puts pre_str + any_test_failed?(test_results).to_s
      end

      def report_number_of_tests(groups)
        name = @runner.test_file_name
        num_processes = groups.size
        num_tests = groups.map(&:size).inject(:+)
        puts division_str
        puts pre_str + "#{num_processes} processes for #{num_tests} #{name}s, ~ #{num_tests / groups.size} #{name}s per process"
        #puts division_str
      end

      # add by Hub
      # show test env address
      def report_address_of_env(address)
        if $mode == :remote
          node_name = Actir::Config.get("config.test_mode.docker.name")
          address.each_with_index do |ip, i|
            puts " " + $env + node_name + (i+1).to_s + " : " + ip
          end
        else
          puts " " + "local"
        end
        puts division_str
      end

      #add by Hub
      #show result of every process exec testcases 
      #this func will last for a while due to the big logfile
      def show_process_serialize(num_processes, options)
        if options[:log]
          puts "\n" + division_str + pre_str + "SHOW_PROCESS_LOG--START\n" + division_str
          for i in 0..(num_processes-1)
            Actir::ParallelTests::Test::Logger.show_log(i)
            puts division_str
          end
          puts division_str + pre_str + "SHOW_PROCESS_LOG--END\n" + division_str
        end
      end

      #exit with correct status code so rake parallel:test && echo 123 works
      def any_test_failed?(test_results)
        test_results.any? { |result| result[:exit_status] != 0 }
      end

      def parse_options!(argv)
        options = {}
        @runner = load_runner("test")
        OptionParser.new do |opts|
          opts.banner = <<-BANNER.gsub(/^          /, '')
            Run all tests in parallel
            Usage: ruby [switches] [--] [files & folders]
            Options are:
          BANNER
          opts.on("-n [PROCESSES]", Integer, "How many processes to use, default: 1") { |n| options[:count] = n }
          opts.on("--group-by [TYPE]", <<-TEXT.gsub(/^          /, '')
          group tests by:
                      found - order of finding files
                      filesize - by size of the file
                      default - filesize
            TEXT
            ) { |type| options[:group_by] = type.to_sym }
          opts.on("-r [TIMES]", "--rerun [TIMES]", Integer, "rerun times for failure&error testcase, default: 0") { |n| options[:rerun] = n }
          #opts.on("-m [FLOAT]", "--multiply-processes [FLOAT]", Float, "use given number as a multiplier of processes to run") { |multiply| options[:multiply] = multiply }
          opts.on("-i", "--isolate",
            "Do not run any other tests in the group used by --single(-s)") do |pattern|
            options[:isolate] = true
          end
          opts.on("-e", "--exec [COMMAND]", "execute this code parallel") { |path| options[:execute] = path }
          opts.on("--serialize-stdout", "Serialize stdout output, nothing will be written until everything is done") { options[:serialize_stdout] = true }
          opts.on("--combine-stderr", "Combine stderr into stdout, useful in conjunction with --serialize-stdout") { options[:combine_stderr] = true }
          opts.on("--non-parallel", "execute same commands but do not in parallel, needs --exec") { options[:non_parallel] = true }
          opts.on("--nice", "execute test commands with low priority") { options[:nice] = true }
          opts.on("--verbose", "Print more output") { options[:verbose] = true }
          opts.on("--log", "record exec result to logfile") { options[:log] = true}
          opts.on("--report", "make a report to show the test result") { options[:report] = true}
          opts.on("--remote", "run testcase in remote environment") { options[:mode] = :remote }
          opts.on("--local", "run testcase in local environment") { options[:mode] = :local }
          # 填写预发环境，目前只支持bjpre2-4，别的后续再添加
          opts.on("-p", "--pre [PRE]", <<-TEXT.gsub(/^          /, '')
          set pre environment to run testcase:
                      bjpre2
                      bjpre3
                      bjpre4
            TEXT
            ) { |pre| pre = "online" if ( pre != "bjpre2" && pre != "bjpre3" && pre != "bjpre4"); options[:pre_name] = pre }
          #add by Hub
          #-u commnd, update baifubao's cookies
          opts.on("-u", "--update", "Update Baifubao's cookies") { options[:update] = true }
          #add by Hub 
          #-s commnd, show test mode,and remote env ipaddress
          opts.on("-s", "--show [PATH]", "Show Test Mode") do |path|
            abort "Please input project directory path!" if path == nil
            $project_path = File.join(Dir.pwd, path)
            puts division_str
            if Actir::Config.get("config.test_mode.env") == :local
              puts "mode : Local"
            else
              puts "mode : Remote"
              node_name = Actir::Config.get("config.test_mode.docker.name")
              address = Actir::Remote.get_remote_address
              puts "node_num : " + address.size.to_s
              address.each_with_index do |address, i|
                puts $env + node_name + (i+1).to_s + " : " + address
              end
            end
            puts division_str
            exit
          end
          opts.on("-h", "--help", "Show this.") { puts opts; exit }
        end.parse!(argv)

        if options[:count] == 0
          options.delete(:count)
          options[:non_parallel] = true
        end

        abort "Pass files or folders to run" if argv.empty? && !options[:execute]

        #如果argv为空,则默认执行所有测试文件
        #遍历testcode下所有文件，组成字符串
        options[:files] = argv
        get_project_path(argv)

        options
      end

      #根据传入的测试文件/文件夹的路径，获取测试工程的路径
      def get_project_path(argv)
        testcode_path = ""
        (argv || []).map do |file_or_folder|
          test_path = File.join(Dir.pwd , file_or_folder)
          #获取testcode文件夹的path
          if test_path =~ /(\/.*\/testcode)/
            testcode_path = $1
            break
          end
        end
        #根据testcode path 拿到project的path
        #要求testcode必须是project的下一级/testcode必须是config的平级
        $project_path = File.join(testcode_path, "../")
      end

      def load_runner(type)
        require "actir/parallel_tests/#{type}/runner"
        require "actir/parallel_tests/#{type}/re_run"
        require "actir/parallel_tests/test/logger"
        runner_classname = type.split("_").map(&:capitalize).join.sub("Rspec", "RSpec")
        klass_name = "Actir::ParallelTests::#{runner_classname}::Runner"
        klass_name.split('::').inject(Object) { |x, y| x.const_get(y) }
      end

      def execute_shell_command_in_parallel(command, num_processes, options)
        runs = (0...num_processes).to_a
        results = if options[:non_parallel]
          runs.map do |i|
            Actir::ParallelTests::Test::Runner.execute_command(command, i, num_processes, options)
          end
        else
          execute_in_parallel(runs, num_processes, options) do |i|
            Actir::ParallelTests::Test::Runner.execute_command(command, i, num_processes, options)
          end
        end.flatten

        abort if results.any? { |r| r[:exit_status] != 0 }
      end

      def report_time_taken
        seconds = Actir::ParallelTests.delta { yield }.to_i
        puts "\n" + pre_str + "Cost #{seconds} seconds#{detailed_duration(seconds)}\n"
        puts division_str
      end

      def detailed_duration(seconds)
        parts = [ seconds / 3600, seconds % 3600 / 60, seconds % 60 ].drop_while(&:zero?)
        return if parts.size < 2
        parts = parts.map { |i| "%02d" % i }.join(':').sub(/^0/, '')
        " (#{parts})"
      end

      def final_fail_message
        fail_message = "#{@runner.name}s Failed\n"
        fail_message = "\e[31m#{fail_message}\e[0m" if use_colors?

        division_str + pre_str + fail_message + division_str
      end

      def use_colors?
        $stdout.tty?
      end

      def pre_str
        " Actir : "
      end

      # add by Hub
      # division for Actir report
      def division_str
        "---------------------------------------------------------------------------------------------\n"
      end

      # 生成详细报告
      def detail_report
        @report_path = File.join($project_path, 'test_report')
        Dir::mkdir(@report_path) if not File.directory?(@report_path)
        time = Time.now.strftime('%Y%m%d_%H%M%S')
        file_path = File.join(@report_path, "REPORT_#{time}.html")
        file = File.new(file_path,"w")
        report = HtmlReport.new(file)
      end

    end
  end
end
