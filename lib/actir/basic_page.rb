module Actir

  class BasicPage

    #include PageObject	
    
    def initialize(driver)
      case driver
      #若是浏览器对象
      when Watir::Browser, Browser
        @browser = driver
        #Appium TO-DO
      when Appium::Driver
        @appium = driver
      else
        raise "wrong driver"
      end
    end

    def method_missing(m, *args, &blk)
      if @browser.respond_to? m
        @browser.send(m, *args, &blk)
      elsif @appium.respond_to? m
        @appium.send(m, *args, &blk)
      else
        super
      end
    end 

    def turn_to kls
      raise "Invalid Page Error" unless kls <= Actir::BasicPage
      kls.new(@browser)
    end

    def data_driven hash, &blk
      raise "Argument Error" unless hash.is_a?(Hash)
      hash.each do |mtd, data|
        m_with_eql = (mtd.to_s + '=').to_sym
        if respond_to?(m_with_eql)
          eval "self.#{m_with_eql.to_s}(data)"
        elsif respond_to?(mtd.to_sym)
          self.send(mtd.to_sym).send(data.to_sym) 
        end #if
      end #each
      class_eval &blk if block_given?
    end

  end #BasicPage
end #Actir
