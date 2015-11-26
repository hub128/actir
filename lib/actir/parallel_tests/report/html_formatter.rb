require 'erb'

module Actir
  module ParallelTests
    class HtmlFormatter

      include ERB::Util # For the #h method.
      def initialize(file)
        @file = file
      end

      def print_html_start
        @file.puts HTML_HEADER
        @file.puts REPORT_HEADER
      end


      def print_testsuite_start(testsuite_id, testsuite_name)
        @file.puts "<div id=\"div_testsuite_#{testsuite_id}\" class=\"testsuite passed\">"
        @file.puts "  <dl>"
        @file.puts "    <dt id=\"testsuite_#{testsuite_id}\" class=\"passed\">[Testsuite]: #{h(testsuite_name)}</dt>"
      end

      def print_testsuite_end
        @file.puts "  </dl>"
        @file.puts "</div>"
      end

      def print_testcase_passed(testcase_name)
        @file.puts "    <dd class=\"testcase passed\">"
        @file.puts "      <span class=\"passed_spec_name\">[Testcase]: #{h(testcase_name)}</span>"
        @file.puts "    </dd>"
      end

      def print_testcase_failed(testsuit_name, testcase_name, backtrace, failure_number)
        temp = testcase_name.split(":")
        class_name = testsuit_name.split(":")[1]
        method_name = temp[1]

        #class_full_name  = temp[0].split("/")
        #class_name = class_full_name[class_full_name.length - 1].split(".")[0].camelize
        @file.puts "    <dd class=\"testcase failed\">"
        @file.puts "      <span class=\"failed_spec_name\">[Testcase]: #{h(testcase_name)}</span>"
        @file.puts "      <div id=\"testtab_#{failure_number}\" style=\"float:right\"><a class=\"expand\" href=\"#\" onClick=\"Effect('failure_#{failure_number}',this.parentNode.id);\" >+</a> </div>"
        @file.puts "      <div class=\"failure\" id=\"failure_#{failure_number}\" style=\"display:none;\">"
        @file.puts "        <div class=\"backtrace\"><pre>#{h(backtrace)}</pre> <h6>Failure Screenshots:<h6><img src=\"../screenshots/FAILED_#{method_name}(#{class_name}).png\" hight=\"700\" width=\"800\"></div>"
        @file.puts "      </div>"
        @file.puts "    </dd>"
      end

      def print_summary(testcase_count, failure_count)
        totals =  "#{testcase_count} testcase#{'s' unless testcase_count == 1}, "
        totals << "#{failure_count} failure#{'s' unless failure_count <= 1 }"

        # formatted_duration = "%.5f" % duration

        # @file.puts "<script type=\"text/javascript\">" \
        #   "document.getElementById('duration').innerHTML = \"Finished in " \
        #   "<strong>#{formatted_duration} seconds</strong>\";</script>"
        @file.puts "<script type=\"text/javascript\">" \
          "document.getElementById('totals').innerHTML = \"#{totals}\";</script>"
        @file.puts "</div>"
        @file.puts "</div>"
        @file.puts "</body>"
        @file.puts "</html>"
      end

      def make_testsuite_header_red(testsuite_id)
        @file.puts "    <script type=\"text/javascript\">" \
                     "makeRed('div_testsuite_#{testsuite_id}');</script>"
        @file.puts "    <script type=\"text/javascript\">" \
                     "makeRed('testsuite_#{testsuite_id}');</script>"
      end

      def flush
        @file.flush
      end
      
      private

      def indentation_style(number_of_parents)
        "style=\"margin-left: #{(number_of_parents - 1) * 15}px;\""
      end

        # rubocop:disable LineLength
      REPORT_HEADER = <<-EOF
<div class="test-report">

<div id="test-header">
  <div id="label">
    <h1>UI-Test Report</h1>
  </div>

  <div id="display-filters">
    <input id="passed_checkbox"  name="passed_checkbox"  type="checkbox" checked="checked" onchange="apply_filters()" value="1" /> <label for="passed_checkbox">Passed</label>
    <input id="failed_checkbox"  name="failed_checkbox"  type="checkbox" checked="checked" onchange="apply_filters()" value="2" /> <label for="failed_checkbox">Failed</label>
  </div>

  <div id="summary">
    <p id="totals">&#160;</p>
    <p id="duration">&#160;</p>
  </div>
</div>


<div class="results">
EOF
      # rubocop:enable LineLength

      # rubocop:disable LineLength
      GLOBAL_SCRIPTS = <<-EOF

function addClass(element_id, classname) {
  document.getElementById(element_id).className += (" " + classname);
}

function removeClass(element_id, classname) {
  var elem = document.getElementById(element_id);
  var classlist = elem.className.replace(classname,'');
  elem.className = classlist;
}

function makeRed(element_id) {
  removeClass(element_id, 'passed');
  addClass(element_id,'failed');
}

function apply_filters() {
  var passed_filter = document.getElementById('passed_checkbox').checked;
  var failed_filter = document.getElementById('failed_checkbox').checked;

  assign_display_style("testcase passed", passed_filter);
  assign_display_style("testcase failed", failed_filter);

  assign_display_style_for_group("testsuite passed", passed_filter);
  assign_display_style_for_group("testsuite failed", failed_filter, failed_filter || pending_filter || passed_filter);
}

function get_display_style(display_flag) {
  var style_mode = 'none';
  if (display_flag == true) {
    style_mode = 'block';
  }
  return style_mode;
}

function assign_display_style(classname, display_flag) {
  var style_mode = get_display_style(display_flag);
  var elems = document.getElementsByClassName(classname)
  for (var i=0; i<elems.length;i++) {
    elems[i].style.display = style_mode;
  }
}

function assign_display_style_for_group(classname, display_flag, subgroup_flag) {
  var display_style_mode = get_display_style(display_flag);
  var subgroup_style_mode = get_display_style(subgroup_flag);
  var elems = document.getElementsByClassName(classname)
  for (var i=0; i<elems.length;i++) {
    var style_mode = display_style_mode;
    if ((display_flag != subgroup_flag) && (elems[i].getElementsByTagName('dt')[0].innerHTML.indexOf(", ") != -1)) {
      elems[i].style.display = subgroup_style_mode;
    } else {
      elems[i].style.display = display_style_mode;
    }
  }
}

function $G(Read_Id) { return document.getElementById(Read_Id) }

function Effect(ObjectId,parentId){
  console.log(ObjectId);
var Obj_Display = $G(ObjectId).style.display;
  if (Obj_Display == 'none'){
  Start(ObjectId,'Opens');
  $G(parentId).innerHTML = "<a class=\\"expand\\" href=# onClick=javascript:Effect('"+ObjectId+"','"+parentId+"');>-</a>"
  }else{ 
  Start(ObjectId,'Close');
  $G(parentId).innerHTML = "<a class=\\"expand\\" href=# onClick=javascript:Effect('"+ObjectId+"','"+parentId+"');>+</a>"
  }
}

function Start(ObjId,method){
  var BoxHeight = $G(ObjId).offsetHeight;
  var MinHeight = 5;
  var MaxHeight = 130;
  var BoxAddMax = 1;
  var Every_Add = 0.15;
  var Reduce    = (BoxAddMax - Every_Add);
  var Add       = (BoxAddMax + Every_Add);

  if (method == "Close"){
    var Alter_Close = function(){
      BoxAddMax /= Reduce;
      BoxHeight -= BoxAddMax;
      if (BoxHeight <= MinHeight){
        $G(ObjId).style.display = "none";
        window.clearInterval(BoxAction);
      }
      else $G(ObjId).style.height = BoxHeight;
    }
    var BoxAction = window.setInterval(Alter_Close,1);
  }

  else if (method == "Opens"){
    var Alter_Opens = function(){
      BoxAddMax *= Add;
      BoxHeight += BoxAddMax;
      if (BoxHeight >= MaxHeight){
        $G(ObjId).style.height = MaxHeight;
        window.clearInterval(BoxAction);
      }else{
        $G(ObjId).style.display= "block";
        $G(ObjId).style.height = BoxHeight;
      }
    }
    var BoxAction = window.setInterval(Alter_Opens,1);
  }
}
EOF
        # rubocop:enable LineLength

      GLOBAL_STYLES = <<-EOF
#test-header {
  background: #03b401; color: #fff; height: 4em;
}

.test-report h1 {
  margin: 0px 10px 0px 10px;
  padding: 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  font-size: 1.8em;
  position: absolute;
}

#label {
  float:left;
}

#display-filters {
  float:left;
  padding: 28px 0 0 40%;
  font-family: "Lucida Grande", Helvetica, sans-serif;
}

#summary {
  float:right;
  padding: 5px 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  text-align: right;
}

#summary p {
  margin: 0 0 0 2px;
}

#summary #totals {
  font-size: 1.2em;
}

.testsuite {
  margin: 0 10px 5px;
  background: #fff;
}

.expand {text-decoration:none;}

dl {
  margin: 0; padding: 0 0 5px;
  font: normal 11px "Lucida Grande", Helvetica, sans-serif;
}

dt {
  padding: 3px;
  background: #03b401;
  color: #fff;
  font-weight: bold;
}

dd {
  margin: 5px 0 5px 5px;
  padding: 3px 3px 3px 18px;
}

dd .duration {
  padding-left: 5px;
  text-align: right;
  right: 0px;
  float:right;
}

dd.testcase.passed {
  border-left: 5px solid #03b401;
  border-bottom: 1px solid #03b401;
  background: #DBFFB4; color: #3D7700;
}

dd.testcase.failed {
  border-left: 5px solid #C20000;
  border-bottom: 1px solid #C20000;
  color: #C20000; background: #FFFBD3;
}

dt.failed {
  color: #FFFFFF; background: #C40D0D;
}

#test-header.failed {
  color: #FFFFFF; background: #C40D0D;
}


.backtrace {
  color: #000;
  font-size: 12px;
}

a {
  color: #BE5C00;
}

/* Ruby code, style similar to vibrant ink */
.ruby {
  font-size: 12px;
  font-family: monospace;
  color: white;
  background-color: black;
  padding: 0.1em 0 0.2em 0;
}

.ruby .keyword { color: #FF6600; }
.ruby .constant { color: #339999; }
.ruby .attribute { color: white; }
.ruby .global { color: white; }
.ruby .module { color: white; }
.ruby .class { color: white; }
.ruby .string { color: #66FF00; }
.ruby .ident { color: white; }
.ruby .method { color: #FFCC00; }
.ruby .number { color: white; }
.ruby .char { color: white; }
.ruby .comment { color: #9933CC; }
.ruby .symbol { color: white; }
.ruby .regex { color: #44B4CC; }
.ruby .punct { color: white; }
.ruby .escape { color: white; }
.ruby .interp { color: white; }
.ruby .expr { color: white; }

.ruby .offending { background-color: gray; }
.ruby .linenum {
  width: 75px;
  padding: 0.1em 1em 0.2em 0;
  color: #000000;
  background-color: #FFFBD3;
}
EOF

      HTML_HEADER = <<-EOF
<!DOCTYPE html>
<html lang='en'>
<head>
  <title>Test results</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Expires" content="-1" />
  <meta http-equiv="Pragma" content="no-cache" />
  <style type="text/css">
  body {
    margin: 0;
    padding: 0;
    background: #fff;
    font-size: 80%;
  }
  </style>
  <script type="text/javascript">
    // <![CDATA[
#{GLOBAL_SCRIPTS}
    // ]]>
  </script>
  <style type="text/css">
#{GLOBAL_STYLES}
  </style>
</head>
<body>
EOF
    end
  end
end