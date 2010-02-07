require 'rubygems'
require 'set'

module JIJI
  module Plugin
    
    @@registry = {}
    
    #プラグインを登録する。
    #future:: 機能の識別子
    #instance:: 機能を提供するプラグインインスタンス
    def self.register( future, instance )
      if @@registry.key? future 
        @@registry[future] << instance
      else
        @@registry[future] = [instance]
      end
    end
    
    #プラグインを取得する。
    #future:: 機能の識別子
    #return:: 機能を提供するプラグインの配列
    def self.get( future )
      @@registry.key?(future) ? @@registry[future] : []
    end
    
    # プラグインローダー
    class Loader 
      def initialize
        @loaded = Set.new
      end
      # プラグインをロードする。
      def load
        ($: + Gem.latest_load_paths).each {|dir|
          plugin = File.expand_path "#{dir}/jiji_plugin.rb"
          next unless File.exist? plugin
          next if @loaded.include?( plugin )
          begin 
            Kernel.load plugin
            server_logger.info( "plugin loaded. plugin_path=#{plugin}" ) if server_logger
            @loaded << plugin
          rescue Exception
            if server_logger
              server_logger.error( "plugin load failed. plugin_path=#{plugin}" ) 
              server_logger.error($!)  
            else
              puts "plugin load failed. plugin_path=#{plugin}"
              puts ([$!.to_s] + $!.backtrace).join("\n      ")
            end
          end
        }
      end
      attr :server_logger, true
    end
    
  end
end

