
require 'jiji/util/file_lock'
require "jiji/models"
require 'jiji/util/util'
require 'jiji/operator'
require 'jiji/output'
require 'jiji/util/include_proxy'

module JIJI
  
  #===エージェントを示すマーカーモジュール
  #JIJIではこのモジュールをincludeしたクラスがエージェントとして認識されます。
  #
  module Agent
    
    module Shared #:nodoc:
      @@deleates = {}
      def self.const_missing(id)
        super unless @@deleates
        result = nil
        @@deleates.each_pair{|k,v|
          if v.const_defined?(id)
            result = v.const_get(id)
            break
          end
        }
        result ? result : super
      end
      def self.method_missing(name,*args, &block)
        super unless @@deleates
        target = nil
        @@deleates.each_pair{|k,v|
          if v.respond_to?(name)
            target = v
            break
          end
        }
        target ? target.send( name, *args, &block ) : super
      end
      def self._delegates
        @@deleates
      end
    end
    
    #====エージェントの登録後に1度だけ呼び出される関数。
    #必要に応じてオーバーライドしてください。コンストラクタと違いこのメソッドではoperatorやoutput,loggerが使用可能です。
    def init( )
    end    
    #====レート情報が通知されるメソッドです。
    #エージェントが動作している間順次呼び出されます。 
    #このメソッドをオーバーライドして、シグナルの計算や取り引きを行うロジックを実装してください
    #rates:: JIJI::Rates
    def next_rates( rates )
    end
    #====設定可能なプロパティの一覧を返します。
    #必要に応じてオーバーライドしてください。
    #戻り値:: JIJI::Agent::Propertyの配列
    def property_infos
      []
    end
    #====設定されたプロパティを取得します。
    def properties
      @properties
    end    
    #====プロパティを設定します。
    def properties=( properties )
      @properties = properties
      properties.each_pair {|k,v|
        instance_variable_set("@#{k}", v)
      }
    end
    
    #====エージェントの説明を返します。
    #必要に応じてオーバーライドしてください。
    def description
      ""
    end
    
    # オペレータ
    attr :operator, true
    # エラーロガー
    attr :logger, true
    # データの出力先
    attr :output, true
        
    #===エージェントのプロパティ
    class Property
      include JIJI::Util::Model
      include JIJI::Util::JsonSupport
      #====コンストラクタ
      #id:: プロパティID
      #name:: UIでの表示名
      #default_value:: プロパティの初期値
      #type:: 種類
      def initialize( id, name, default_value=nil, type=:string )
        @id = id
        @name = name
        @default = default_value
        @type = type
      end
      #プロパティID。
      #JIJI::Agent#properties=(props)で渡されるハッシュのキーになります。設定必須です。
      attr :id, true
      # UIでの表示名。設定必須です。
      attr :name, true
      # プロパティの初期値。
      attr :default, true
      # 種類。:string or :numberが指定可能。指定しない場合、:stringが指定されたものとみなされます。
      attr :type, true
    end    
  
  end
  
  #===一定期間ごとに通知を受け取るエージェントの基底クラス。
  class PeriodicallyAgent
    include JIJI::Agent
    include_proxy JIJI::Agent::Shared
    
    #====コンストラクタ
    #period:: レートの通知を受け取る間隔(分)の初期値
    def initialize( period=10 )
      @period = period
      @start = nil
      @rates = nil
    end
    def next_rates( rates )
      @rates = PeriodicallyRates.new( rates.pair_infos ) unless @rates
      now = rates.time
      @start = now unless @start
      @rates << rates
      if ( now - @start ) > @period*60
        next_period_rates( @rates )
        @rates = PeriodicallyRates.new( rates.pair_infos )
        @rates.start_time = now
        @start = now
      end
    end
    def property_infos
      super() + [Property.new(:period, "レートの通知を受け取る間隔(分)", 10, :number)]
    end
    #====レート情報が通知されるメソッドです。
    #エージェントが動作している間順次呼び出されます。 
    #このメソッドをオーバーライドして、シグナルの計算や取り引きを行うロジックを実装してください
    #rates:: JIJI::PeriodicallyRates
    def next_period_rates( rates )
    end
  end
  
end