# Actir

Application Concurrence Test in Ruby.

## 安装

通过Rake本地安装gem包：

    $ rake install

或者通过rubygems远程安装

    $ sudo gem install actir
    
如果是Mac OS X 10.11版本以上的系统，要么关闭rootless机制，或者：

    $ sudo gem install actir -n /usr/local/bin
    

## 使用须知

### 测试工程结构
  - **config**：配置文件  
    --- config.yaml：总体配置文件,test_mode相关的配置项必须要填;  
  - **elements**：页面元素  
    - |--- `components`：公用页面元素方法, 包装成`Module`;  
    - |--- `pages`：页面元素封装的方法,可以继承自`Actir::BasicPage`,已经封装了部分公用方法;
    - |--- `items`：根据业务抽象出的类;
    - |--- `user`：根据系统业务抽象出的角色及其Action; 
  - **testcode**： 测试用例, 文件和用例方法都要以`test`开头, 执行之前需要初始化`Actir::Initializer.new(project_path)`，`project_path`为测试工程根目录;

### 浏览器对象
``` ruby
Browser.new(type, *args)
```
Browser重新封装了Watir以及Selenium的初始化浏览器的方法  
- **type**：指定初始化浏览器的类型,可以指定www/wap两类  
- **args**：
  - `:browser`：浏览器类型,可以支持 :chrome/:phantomjs/:firefox, 默认为chrome  
  - `:agent`：user agent类型,可以支持 :iphone/:andriod_phone, 默认为iphone  
  - `:mode`：启动模式,支持 :local/:remote, 默认为local  
  - `:url`： 配合mode为remote的模式,指定远程机器的url,需要 IP+端口号  

### Initializer自动加载工程文件
``` ruby
Actir::Initializer.new(project_path)
```
-  自动require所有的elements内的文件并自动定义每个页面类对应的方法。如: 某页面类名为`LoginPage`,则会自动定义出`login_page`方法供`Browser`对象调用
- 可以直接调用Watir::Browser的所有方法  
  
``` ruby
browser = Browser.new(:wap)
browser.login_page.login("xxx")
# 调用Watir::Browser对象的方法
browser.refresh
```

### 执行测试用例

    $ actir [switches] [--] [files & folders]
    $ actir testcode/test_refund/test_full_refund.rb
    $ actir testcode
    
指定执行某个用例文件中的某个方法：

    $ actir testcode/test_pay/test_pay.rb -n test_ecard

指定用例失败重试次数：

    $ actir testcode/test_pay/test_pay.rb -r 2

输出html格式的测试报告：

    $ actir testcode/test_pay/test_pay.rb -r 2 --report


> 可使用`actir -h` 了解更多的运行参数
> 