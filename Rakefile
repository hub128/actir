# encoding: utf-8
require 'rake'

def is_taobao_gemsource?
  source = `gem sources -l`
  source.include? "taobao"
end

unless is_taobao_gemsource?
  # 修改RubyGems源
  sh "gem sources --remove https://rubygems.org/"
  sh "gem sources -a https://ruby.taobao.org/"
  sh "gem sources -l"
end

def check_gem_available(gemName, versionLimit=nil)
  isAvailable = false
  begin
    if versionLimit == nil
      gem gemName
    else
      gem gemName, versionLimit
    end
    isAvailable = true
  rescue LoadError
  end
  isAvailable
end

def is_root?
  name = `whoami`
  name.include? "root"
end

def sudo_str
 "sudo" unless is_root?
end

# 判断是否安装bundler包，若没有，则安装，并require
sh "#{sudo_str} gem install bundler" if check_gem_available("bundler") == false

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actir/version'

# Defines gem name.
def repo_name
  'actir'
end

def version
  Actir::VERSION
end

task :package do
  sh "#{sudo_str} bundle update"
end

task :gem do
  sh "#{sudo_str} rm -rf #{repo_name}-#{version}.gem"
  sh "#{sudo_str} gem build #{repo_name}.gemspec"
end

task :uninstall do
  sh "#{sudo_str} gem uninstall #{repo_name} -a -x"
end

task :install => [:package, :gem, :uninstall] do
  sh "#{sudo_str} gem install #{repo_name}"
end
