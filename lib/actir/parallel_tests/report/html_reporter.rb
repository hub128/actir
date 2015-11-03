require 'actir/parallel_tests/report/html_formatter'

module Actir
  module ParallelTests
    class HtmlReport

      def initialize(file)
        @testsuites = $testsuites
        @testsuite_number = 0
        @testcase_number = 0
        @failure_number = 0
        # @duration = 0
        @formatter = HtmlFormatter.new(file)

        result_print
      end

      def result_print
        # 没有result信息
        return 0 if @testsuites == nil

        report_start
        @testsuites.each do |testsuite|
          testsuite_print(testsuite)
        end

        summary = {:testcase_count => @testcase_number, 
                   :failure_count => @failure_number}
        summary_print(summary)
      end

      def report_start
        @formatter.print_html_start
        @formatter.flush
      end

      def testsuite_print(testsuite)
        @testsuite_red = false
        @testsuite_number += 1
        @formatter.print_testsuite_start(@testsuite_number, testsuite[:testsuite_name])
        testcases = testsuite[:testcases] 
        testcases.each do |testcase|
          if(testcase[:success] == true)
            testcase_passed_print(testcase[:testcase_name])
          else
            testcase_failed_print(testcase[:testcase_name], testcase[:detail])
          end
        end
        @formatter.print_testsuite_end
        @formatter.flush
      end

      def testcase_passed_print(testcase_name)
        @testcase_number += 1
        @formatter.print_testcase_passed(testcase_name)
        @formatter.flush
      end

      def testcase_failed_print(testcase_name, details)
        @testcase_number += 1
        @failure_number += 1

        unless @testsuite_red
          @testsuite_red = true
          @formatter.make_testsuite_header_red(@testsuite_number)
        end

        @formatter.print_testcase_failed(testcase_name, details, @failure_number)
        @formatter.flush
      end


      def summary_print(summary)
        @formatter.print_summary(
          # summary[:duration],
          summary[:testcase_count],
          summary[:failure_count]
        )
        @formatter.flush
      end

    private

      # If these methods are declared with attr_reader Ruby will issue a
      # warning because they are private.
      # rubocop:disable Style/TrivialAccessors

      # The number of the currently running testsuite.
      # def testsuite_number
      #   @testsuite_number
      # end

      # The number of the currently running testcase (a global counter).
      # def testcase_number
      #   @testcase_number
      # end
      # rubocop:enable Style/TrivialAccessors

      # Override this method if you wish to file extra HTML for a failed
      # spec. For testcase, you could file links to images or other files
      # produced during the specs.
      # def extra_failure_content(failure)
      #   RSpec::Support.require_rspec_core "formatters/snippet_extractor"
      #   backtrace = failure.exception.backtrace.map do |line|
      #     RSpec.configuration.backtrace_formatter.backtrace_line(line)
      #   end
      #   backtrace.compact!
      #   @snippet_extractor ||= SnippetExtractor.new
      #   "    <pre class=\"ruby\"><code>#{@snippet_extractor.snippet(backtrace)}</code></pre>"
      # end
    end
  end
end
