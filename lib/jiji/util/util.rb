
require 'kconv'
require 'jiji/error'

module JIJI
  
  module Util
  
  module_function
    
    #ブロック内で例外が発生したらログに出力する。
    #発生した例外は内部で握る。
    def log_if_error( logger ) 
      begin
        return yield if block_given?
      rescue Exception
        logger.error($!)
      end
    end
    #ブロック内で例外が発生したらログに出力する。
    #ログ出力後、例外を再スローする。
    def log_if_error_and_throw( logger ) 
      begin
        return yield if block_given?
      rescue Exception
        logger.error($!)
        throw $!
      end
    end    

    # 文字列をbase64でエンコードする
    def encode( str ) 
      [str].pack("m").gsub(/\//, "_").gsub(/\n/, "")
    end
    # base64でエンコードした文字列をデコードする
    def decode( str )
      str.gsub(/_/, "/").unpack('m')[0]
    end
    
    # モデルオブジェクトの基底モジュール
    module Model
      
      # オブジェクト比較メソッド
      def ==(other)
        _eql?(other) { |a,b| a == b }
      end
      def ===(other)
        _eql?(other) { |a,b| a === b }
      end
      def eql?(other)
        _eql?(other) { |a,b| a.eql? b }
      end
      def hash
        hash = 0
        values.each {|v|
          hash = v.hash + 31 * hash
        }
        return hash
      end
    protected
      def values
        values = []
        values << self.class
        instance_variables.each { |name|
          values << instance_variable_get(name) 
        }
        return values
      end
    private
      def _eql?(other, &block)
        return false if other == nil
        return true if self.equal? other
        return false unless other.kind_of?(JIJI::Util::Model)
        a = values
        b = other.values
        return false if a.length != b.length
        a.length.times{|i|
          return false unless block.call( a[i], b[i] )
        }
        return true
      end
    end
    
    module JsonSupport   
      def to_json
        buff = "{"
        instance_variables.each { |name|
          buff << "#{name[1..-1].to_json}:#{instance_variable_get(name).to_json},"
        }
        buff.chop!
        buff << "}"
      end
    end
    
      
    # 期間を示す文字列を解析する
    def self.parse_scale( scale )
      return nil if  scale.to_s == "raw"
      unless scale.to_s =~ /(\d+)([smhd])/
        raise JIJI::UserError.new( JIJI::ERROR_ALREADY_EXIST, "illegal scale. scale=#{scale}") 
      end
      return case $2
        when "s"; $1.to_i
        when "m"; $1.to_i * 60
        when "h"; $1.to_i * 60 * 60
        when "d"; $1.to_i * 60 * 60 * 24
      end
    end
          
  
  end
end