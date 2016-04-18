require 'pathname'

module Actir
  class Initializer

    #config content
    attr_accessor :config

    def initialize project_path
      $project_path ||= project_path
      $:.unshift($project_path)
      $config = load_config
      load_elements
    end

    def load_elements
      @elements_path = File.join($project_path, 'elements')
      load_item
      load_components
      load_user
      load_pages
    end

    def load_config
      @config_path = File.join($project_path, 'config')
      @config = {}
      Dir.glob(File.join @config_path, '**', '*.yaml').select{ |c| c =~ /\.yaml$/ }.each do |config|
        puts "#{config}" if $debug
        #获取配置文件名字
        config =~ /config\/(.*)\.yaml/
        config_name = $1
        @config.store(config_name, Actir::Config.get_content(config))
      end
      @config
    end

    def load_item
      @item_path = File.join(@elements_path, 'item')
      Dir.glob(File.join @item_path, '**', '*.rb').select {|p| p =~ /\.rb$/}.each do |i|
        puts i if $debug
        require "#{i}" 
      end #each
    end

    def load_user
      @user_path = File.join(@elements_path, 'user')
      Dir.glob(File.join @user_path, '**', '*.rb').select {|p| p =~ /\.rb$/}.each do |u|
        puts u if $debug
        require "#{u}" 
      end #each
    end

    def load_components
      @components_path = File.join(@elements_path, 'components')
      Dir.glob(File.join @components_path, '**', '*.rb').select {|p| p =~ /\.rb$/}.each do |c|
        puts c if $debug
        require "#{c}" 
      end #each
    end
    
    def load_pages
      @pages_path = File.join(@elements_path, 'pages')
      Dir.glob(File.join @pages_path, '**', '*.rb').select { |p| p =~ /\.rb$/ }.each do |page|
        puts "#{page}"if $debug
        require "#{page}"
      end #each
    end
    
  end
end
