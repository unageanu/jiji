
require 'jiji/util/util'
require "jiji/dao/timed_data_dao"

module JIJI

  #===レートの集合
  #通貨ペアコード(:EURJPYのようなシンボル)をキーとしてJIJI::Rateを保持します。
  #
  #  rates = <省略>
  #  
  #  #EURJPYのレートを取得。
  #  rate = rates[:EURJPY] #=> JIJI::Rate
  #
  #  #bidレート,askレートを取得
  #  p rate.bid
  #  p rate.ask
  #
  class Rates < Hash

    include JIJI::Util::Model

    def initialize( pair_infos, list, time=Time.now ) #:nodoc:
      super()
      @pair_infos = pair_infos
      @time = time
      list.each_pair { |k,info|
        self[k] = Rate.new( info.bid.to_f, info.ask.to_f,
          info.sell_swap.to_f, info.buy_swap.to_f, time)
      }
    end
    # 通貨ペアの情報(取引数量など)
    attr_reader :pair_infos
    # 現在時刻
    attr_reader :time
  end

  #==レート
  class Rate

    include JIJI::Util::Model
    include JIJI::Dao::TimedData

    def initialize( bid=nil, ask=nil, sell_swap=nil, buy_swap=nil, time=nil ) #:nodoc:
      @bid = bid
      @ask = ask
      @sell_swap = sell_swap
      @buy_swap = buy_swap
      @time = time
    end
    # 値を配列で取得する
    def values #:nodoc:
      [bid,ask,sell_swap,buy_swap,time.to_i]
    end
    # 値を配列で設定する
    def values=(values) #:nodoc:
      @bid = values[0].to_f
      @ask = values[1].to_f
      @sell_swap = values[2].to_f
      @buy_swap  = values[3].to_f
    end
    #bidレート
    attr_reader :bid
    #askレート
    attr_reader :ask
    #売りスワップ
    attr_reader :sell_swap
    #買いスワップ
    attr_reader :buy_swap
  end

  #===一定期間のレートの集合
  #通貨ペアコード(:EURJPYのようなシンボル)をキーとしてJIJI::PeriodicallyRateを保持します。
  #
  #  rates = <省略>
  #  
  #  #EURJPYのレートを取得。
  #  rate = rates[:EURJPY] #=> JIJI::PeriodicallyRate
  #
  #  #bidレートの高値、安値を取得
  #  bid = rate.bid
  #  p bid.max
  #  p bid.min
  #
  class  PeriodicallyRates < Hash

    include JIJI::Util::Model
    #====コンストラクタ
    #pair_infos:: 通貨ペアの情報
    #list:: 初期データ
    def initialize( pair_infos, list=[] ) #:nodoc:
      super()
      @pair_infos = pair_infos
      list.each {|rates|
        self << rates
      }
    end
    #====JIJI::Ratesを追加し各値の四本値を再計算します。
    #rates:: JIJI::Rates
    def <<(rates)
      now = rates.time
      @start_time = now unless @start_time
      @end_time   = now
      rates.each_pair { |code,rate|
        self[code] = PeriodicallyRate.new unless key? code
        self[code] << rate
      }
    end
    def time #:nodoc:
      @start_time
    end
    #通貨ペアの情報(取引数量など)
    attr_reader :pair_infos
    #集計開始日時
    attr :start_time, true
    #集計終了日時
    attr :end_time, true
  end

  #===一定期間のレート
  #bid,ask,sell_swap,buy_swapの各値が四本値(JIJI::PeriodicallyValue)で保持されます。
  class PeriodicallyRate

    include JIJI::Util::Model
    include JIJI::Dao::TimedData
    
    #====コンストラクタ
    #list:: 初期データ
    def initialize( list=[] ) #:nodoc:
      @bid = PeriodicallyValue.new
      @ask = PeriodicallyValue.new
      @sell_swap = PeriodicallyValue.new
      @buy_swap  = PeriodicallyValue.new
      list.each { |item|
        self << item
      }
    end
    #====JIJI::Rateを追加し各値の四本値を再計算します。
    #rate:: JIJI::Rate
    def <<( rate ) #:nodoc:
      @bid << rate.bid
      @ask << rate.ask
      @sell_swap << rate.sell_swap
      @buy_swap  << rate.buy_swap
      @start_time = rate.time unless @start_time
      @end_time = rate.time
    end
    # 値を配列で取得する
    def values #:nodoc:
      bid.values + ask.values + sell_swap.values + buy_swap.values \
        + [@start_time.to_i, @end_time.to_i]
    end
    # 値を配列で設定する
    def values=(values) #:nodoc:
      @bid.values = values[0..3]
      @ask.values = values[4..7]
      @sell_swap.values = values[8..11]
      @buy_swap.values = values[12..15]
      @start_time = Time.at(values[16].to_i)
      @end_time = Time.at(values[17].to_i)
    end
    def time #:nodoc:
      @end_time
    end
    def time=(t) #:nodoc:
      @end_time = t
    end
    #bidレート
    attr_reader :bid
    #askレート
    attr_reader :ask
    #売りスワップ
    attr_reader :sell_swap
    #買いスワップ
    attr_reader :buy_swap
    #集計開始日時
    attr :start_time, true
    #集計終了日時
    attr :end_time, true
  end

  #===一定期間の値
  #始値、終値、高値、安値の四本値
  class PeriodicallyValue

    include JIJI::Util::Model
    
    #====コンストラクタ
    #list:: 初期データ
    def initialize( list=[] )
      list.each { |item|
        self << item
      }
    end
    #====値を追加し四本値を再計算します。
    #value:: 値
    def <<( value )
      @start = value if @start == nil
      @end = value
      @max = value if @max == nil || value > @max
      @min = value if @min == nil || value < @min
    end
    # 値を配列で取得する
    def values #:nodoc:
      [@start, @end, @max, @min]
    end
    # 値を配列で設定する
    def values=(values) #:nodoc:
      @start = values[0].to_f
      @end   = values[1].to_f
      @max   = values[2].to_f
      @min   = values[3].to_f
    end
    #始値
    attr :start
    #終値
    attr :end
    #高値
    attr :max
    #安値
    attr :min
  end
end