
require 'thread'

module JIJI
  
   #==コレクターからのレートの通知を受け取るクラス。
  class ObserverManager
    #コンストラクタ
    #observers:: オブサーバー
    #logger:: ロガー
    def initialize( observers, logger )
     @logger = logger
     @observers = observers
   end
   #レートの通知を受ける
   #rates:: レート
    def next_rates( rates )
      @observers.each {|w|
        w.next_rates( rates )
      }
    end
    #オブザーバーを追加する
    #observer:: オブザーバー
    def <<(observer)
      @observers << observer
    end
    #通知を停止する
    def stop 
    end
    #ロガー
    attr :logger, true
  end

  
  #==コレクターからのレートの通知を受け取り、別スレッドで処理するクラス。
  #- 登録されたオブザーバーごとに専用のスレッドを起こして情報を通知する。
  #- スレッドを破棄する必要があるため、必ずstopで停止すること。
  class WorkerThreadObserverManager
    #コンストラクタ
    #observers:: オブサーバー
    #logger:: ロガー
    def initialize( observers, logger )
     @logger = logger
     @workers = observers.map {|o|
       Worker.new( o, @logger )
     }
   end
   #レートの通知を受ける
   #rates:: レート
    def next_rates( rates )
      @workers.each {|w|
        w.next_rates( rates )
      }
    end
    #オブザーバーを追加する
    #observer:: オブザーバー
    def <<(observer)
      @workers << Worker.new( observer, @logger )
    end
    #通知を停止する
    def stop 
      @logger.info( "observer manager stop" )
      @workers.each {|w|  w.alive = false }
      @workers.each {|w|  w.thread.join }
      @workers.clear
    end
    #ロガー
    attr :logger, true
  end
  
  # ワーカースレッド
  class Worker
    def initialize( observer, logger )
      @logger = logger
      @alive = true
      @alive_mutex = Mutex.new
      @q = Queue.new
      @thread = Thread.start {
        while( !@q.empty? || alive? )
          JIJI::Util.log_if_error( @logger ) {
            rates = @q.pop 
            observer.next_rates( rates ) if rates != nil
          }
        end
      }
    end
    def next_rates( rates )
      @q.push rates
    end
    def alive?
      @alive_mutex.synchronize {
        @alive
      }
    end
    def alive=(value)
      @alive_mutex.synchronize {
        @alive = value
        @q.push nil # 眠れるスレッドをたたき起こす。
      }
    end
    
    attr_reader :thread
  end
  
end