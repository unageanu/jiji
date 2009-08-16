
require "jiji/models"
require "jiji/dao/rate_dao"
require 'jiji/util/util'
require "thread"
require "date"

module JIJI

  #
  #==レート一覧を取得しオブザーバーに通知するクラス
  #- 設定値で指定された間隔でレート一覧を取得し、JIJI::ObserverManagerに通知する。
  #
  class Collector

    #コンストラクタ
    def initialize
      @alive = false
      @state_mutex = Mutex.new
      @end_mutex = Mutex.new
      @future = nil
      @state_mutex.synchronize {
        @state = :WAITING
        @listeners = []
      }
    end

    #収集を開始する。
    def start
      @state_mutex.synchronize {
        @state = :RUNNING
      }
      @end_mutex.synchronize {
        @alive = true
        @future = Thread.fork {
          start_collect
          :finished
        }
      }
    end

    #収集を停止する。
    #- サーバーが終了した際に呼び出される。
    #- JIJI::ObserverManagerの破棄も内部で行う。
    def stop
      @end_mutex.synchronize {
        return unless @alive # 実行していない場合何もしない。
        @alive = false
      }
      # スレッドの完了を待つ
      @future.value
    end

    #進捗(%を示す整数)を取得する
    def progress
      0 # リアルトレードでは常に0
    end
    #状態を取得する。
    #戻り値:: 状態を示すシンボル。
    #           :WAITING ..  実行待ち状態
    #           :RUNNING ..  実行中
    #           :CANCELED ..  実行がキャンセルされた(JIJI::BackTestCollectorのみ)
    #           :FINISHED ..  実行完了(JIJI::BackTestCollectorのみ)
    #           :ERROR_END ..  エラー終了(JIJI::BackTestCollectorのみ)
    def state
      @state_mutex.synchronize {
        @state
      }
    end

    #待ち時間
    attr :wait_time, true
    #コンフィグレーション
    attr :conf, true
    #JIJI::ObserverManager
    attr :observer_manager, true
    #ロガー
    attr :logger, true
    #証券会社アクセスクライアント
    attr :client, true
    #情報取得中に発生したエラー
    attr_reader :error

    # 収集終了の通知を受けるリスナ。
    attr :listeners, true

  private
    def start_collect
      begin
        @logger.info( "collector start" )
        JIJI::Util.log_if_error_and_throw( @logger ) {
          # 通貨ペア情報を取得
          @pair_infos = @client.list_pairs.inject({}){|r,i|
            r[i.name.to_sym] = i
            r
          }
        }
        collect
      rescue Exception
        @error = $!
      ensure
        @logger.info( "collector finished" )
        JIJI::Util.log_if_error( @logger ) {
          @observer_manager.stop # 終了を通知
          state = @end_mutex.synchronize { @alive } \
            ? ( @error ? :ERROR_END : :FINISHED ) \
            : :CANCELED
          @state_mutex.synchronize {
            @state = state
          }
          @end_mutex.synchronize { @alive = false }

          # リスナに通知
          callback( :on_finished, @state, Time.at(@now || Time.now) )
        }
      end
    end
    def collect
      while( @end_mutex.synchronize { @alive } ) #停止されるまでループ
        JIJI::Util.log_if_error( @logger ) {
          begin
            #レート
            list = @client.list_rates
            #オブザーバーに通知
            @observer_manager.next_rates Rates.new( @pair_infos, list )
            @now = Time.now # 現在時刻を更新
          ensure
            # 一定期間待つ
            sleep @conf.get([:collector, :wait_time], 10 )
          end
        }
      end
    end
    # リスナにイベントを通知する
    def callback( method, *args )
      @listeners.each {|l|
        JIJI::Util.log_if_error( @logger ) {
          l.send(method, *args ) if l.respond_to? method
        }
      }
    end
  end

  #
  #==指定された期間のログからレート一覧を取得し、JIJI::ObserverManagerに通知するクラス
  #
  class BackTestCollector < Collector

    #コンストラクタ
    #rate_dao:: レート情報の取得先とするJIJI::RateDao
    #start_date:: 読み込み開始日時
    #end_date:: 読み込み終了日時
    def initialize( rate_dao, start_date, end_date )
      super()
      @dao = rate_dao
      @start_date = start_date
      @end_date  =  end_date
      @progress = 0
    end
    def collect
      JIJI::Util.log_if_error_and_throw( @logger ) {
        callback( :on_progress_changed, @progress )
        begin
          pairs =  @dao.list_pairs
          if pairs.length > 0
            @start_date = @start_date || Time.at( @dao.dao(pairs[0]).first_time(:raw) )
            @end_date = @end_date || Time.at( @dao.dao(pairs[0]).last_time(:raw) )
          else
            @start_date = @start_date || 0
            @end_date = @end_date || Time.now
          end
          @now = @start_date.to_i
          @dao.each_all_pair_rates(:raw, @start_date, @end_date ) {|rates|
            each_rate(rates)
            # キャンセルチェック
            if ( !@end_mutex.synchronize { @alive } )
              @logger.info( "collector canceled" )
              break
            end
          }
        ensure
          @state_mutex.synchronize {
            @progress = 100
          }
          callback( :on_progress_changed, @progress )
        end
      }
    end
    def progress
      @state_mutex.synchronize {
        @progress
      }
    end

    #レートDAO
    attr_reader :dao
  private
    # レートを1つ読み込んで通知する。
    def each_rate(rates)
      begin
        tmp = {}
        time = nil
        rates.each_pair {|k,v|
          tmp[k] = Rate.new(
            v[0].to_f, v[1].to_f, v[2].to_i, v[3].to_i, Time.at(v[4].to_i) )
          time = Time.at(v[4].to_i) unless time
        }
        @observer_manager.next_rates(Rates.new( @pair_infos, tmp, time ))
      ensure

        # 進捗を更新
        if @start_date !=nil && @end_date !=nil
          @state_mutex.synchronize {
            @now = @end_date.to_i # 現在時刻を更新
            current = time.to_i - @start_date.to_i
            all = @end_date.to_i - @start_date.to_i
            @progress = ( current*100 / all ).to_i
          }
          callback( :on_progress_changed, @progress )
        end
      end
    end

  end

end