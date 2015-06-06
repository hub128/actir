# Actir

Application Concurrence Test in Ruby.

## Installation

git clone code and then execute:

    $ rake install

Or install it yourself as:

    $ gem install actir

## Usage

使用须知:  
1. 对应测试工程结构如下  
  &emsp;config -- 配置文件  
  &emsp;&emsp;|-config.yaml -- 总体配置文件,test_mode相关的配置项必须要填  
  &emsp;elements  
  &emsp;&emsp;|-components -- 公用页面元素方法  
  &emsp;&emsp;|-pages -- 页面元素封装的方法,可以继承自Actir::BasicPage,已经封装了部分公用方法  
  &emsp;testcode -- 测试用例,执行之前需要初始化 Actir::Initializer.new(project_path)
              
2.project_path:测试工程根目录

3.Browser.new(type, *args):  
  &emsp;Browser重新封装了watir以及selenium的初始化浏览器的方法  
  &emsp;1).type指定初始化浏览器的类型,可以指定www/wap两类  
  &emsp;2).*args:  
  &emsp;:browser - 浏览器类型,可以支持 :chrome/:phantomjs/:firefox, 默认为chrome  
  &emsp;:agent   - user agent类型,可以支持 :iphone/:andriod_phone, 默认为iphone  
  &emsp;:mode    - 启动模式,支持 :local/:remote, 默认为local  
  &emsp;:url     - 配合mode为remote的模式,指定远程机器的url,需要 IP+端口号  

4.初始化会自动require所有的elements内的文件并自动定义每个页面类对应的方法  
  &emsp;如: 某页面类名为LoginPage,则会自动定义出login_page方法  
  &emsp;3中初始化出的browser对象,可以直接调用login_page方法  
  &emsp;也可以直接调用Watir::Browser对应的所有方法  
  &emsp;如:browser = Browser.new(type, *args)  
  &emsp;&emsp;&emsp;browser.login_page.xxx (xxx为LoginPage中定义的方法)

## Contributing

1. Fork it ( https://github.com/hub128/actir.git )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
