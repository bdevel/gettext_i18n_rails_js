
# Should be defined by GettextI18nRails but may not be using
# the forked version that includes configuration.
unless  GettextI18nRails.respond_to? :options
  
  require 'ostruct'
  module GettextI18nRails
    @@options = OpenStruct.new
    
    def self.options
      @@options
    end
    
    def self.configure(&block)
      block.call(@@options)
    end
  end
  
end
