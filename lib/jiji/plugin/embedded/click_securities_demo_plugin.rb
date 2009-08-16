
require 'jiji/plugin/securities_plugin'
require 'jiji/plugin/embedded/single_click_client'

module JIJI
  module Plugin
    
    # クリック証券デモトレードアクセスプラグイン
    class ClickSecuritiesDemoPlugin
      include JIJI::Plugin::SecuritiesPlugin
      
      #プラグインの識別子を返します。
      def plugin_id
        :click_securities_demo
      end
      #プラグインの表示名を返します。
      def display_name
        "CLICK Securities DEMO Trade"
      end
      #「jiji setting」でユーザーに入力を要求するデータの情報を返します。
      def input_infos
        [ Input.new( :user, "Please input a user name of CLICK Securities DEMO Trade.", false, nil ),
          Input.new( :password, "Please input a password of CLICK Securities DEMO Trade.", true, nil ),
          Input.new( :proxy, "Please input a proxy. example: http://example.com:80 (default: nil )", false, nil )]
      end
      
      #プラグインを初期化します。
      def init_plugin( props, logger ) 
        @client = JIJI::Plugin::SingleClickClient.new( props, logger )
      end
      #プラグインを破棄します。
      def destroy_plugin
        @client.close if @client
      end
      
      #利用可能な通貨ペア一覧を取得します。
      def list_pairs
        pairs = @client.request {|fx| fx.list_currency_pairs }
        return pairs.map {|i| 
          name = convert_currency_pair_code(i[0])
          Pair.new( name, i[1].trade_unit )
        }
      end
      
      #現在のレートを取得します。
      def list_rates
        @client.request {|fx|               
          fx.list_rates.inject({}) {|r,p|
            code = convert_currency_pair_code(p[0])
            r[code] = Rate.new( p[1].bid, p[1].ask, p[1].sell_swap, p[1].buy_swap )
            r
          }
        }
      end
      
      #成り行きで発注を行います。
      def order( pair, sell_or_buy, count )
        result = @client.request{ |fx|
            fx.order( convert_currency_pair_code_r(pair),
              sell_or_buy == :buy ? ClickClient::FX::BUY : ClickClient::FX::SELL,  count )
        }
        return JIJI::Plugin::SecuritiesPlugin::Position.new( result.open_interest_no )
      end
      
      #建玉を決済します。
      def commit( position_id, count )
        @client.request {|fx| fx.settle( position_id, count ) }
      end
      
      # 通貨ペアコードをシンボルに変換する
      def convert_currency_pair_code(code)
        case code
          when ClickClient::FX::USDJPY
            return :USDJPY
          when ClickClient::FX::EURJPY
            return :EURJPY
          when ClickClient::FX::GBPJPY
            return :GBPJPY
          when ClickClient::FX::AUDJPY
            return :AUDJPY
          when ClickClient::FX::NZDJPY
            return :NZDJPY
          when ClickClient::FX::CADJPY
            return :CADJPY
          when ClickClient::FX::CHFJPY
            return :CHFJPY
          when ClickClient::FX::ZARJPY
            return :ZARJPY
          when ClickClient::FX::EURUSD
            return :EURUSD
          when ClickClient::FX::GBPUSD
            return :GBPUSD
          when ClickClient::FX::AUDUSD
            return :AUDUSD
          when ClickClient::FX::EURCHF
            return :EURCHF
          when ClickClient::FX::GBPCHF
            return :GBPCHF
          when ClickClient::FX::USDCHF
            return :USDCHF
        end
      end
      
      # シンボルを通貨ペアコードに変換する
      def convert_currency_pair_code_r(code)
        case code
          when :USDJPY
            return ClickClient::FX::USDJPY
          when :EURJPY
            return ClickClient::FX::EURJPY
          when :GBPJPY
            return ClickClient::FX::GBPJPY
          when :AUDJPY
            return ClickClient::FX::AUDJPY
          when :NZDJPY
            return ClickClient::FX::NZDJPY
          when :CADJPY
            return ClickClient::FX::CADJPY
          when :CHFJPY
            return ClickClient::FX::CHFJPY
          when :ZARJPY
            return ClickClient::FX::ZARJPY
          when :EURUSD
            return ClickClient::FX::EURUSD
          when :GBPUSD
            return ClickClient::FX::GBPUSD
          when :AUDUSD
            return ClickClient::FX::AUDUSD
          when :EURCHF
            return ClickClient::FX::EURCHF
          when :GBPCHF
            return ClickClient::FX::GBPCHF
          when :USDCHF
            return ClickClient::FX::USDCHF
        end
      end
      
    end
    
  end
end