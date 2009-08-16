
module Signal

  #===一定期間のレートデータを元に値を算出するシグナルの基底クラス
  class RangeSignal
    include Signal
    #====コンストラクタ
    #range:: 集計期間
    def initialize( range=25 )
      @datas = [] # レートを記録するバッファ
      @range = range
    end
    #====次のデータを受け取って指標を返します。
    #data:: 次のデータ
    #戻り値:: 指標。十分なデータが蓄積されていない場合nil
    def next_data( data )
      # バッファのデータを更新
      @datas.push data
      @datas.shift if @datas.length > @range

      # バッファサイズが十分でなければ、nilを返す。
      return nil if @datas.length != @range

      # 算出
      return calculate(@datas)
    end
    # 
    def calculate(datas); end #:nodoc:
     #集計期間
     attr_reader :range
  end

  #===移動平均
  class MovingAverage < RangeSignal
    def calculate(datas) #:nodoc:
      ma( datas )
    end
  end

  #===加重移動平均
  class WeightedMovingAverage < RangeSignal
    def calculate(datas) #:nodoc:
      wma( datas )
    end
  end

  #===指数移動平均
  class ExponentialMovingAverage < RangeSignal
    #====コンストラクタ
    #range:: 集計期間
    #smoothing_coefficient:: 平滑化係数
    def initialize( range=25, smoothing_coefficient=0.1 )
      super(range)
      @sc = smoothing_coefficient
    end
    def calculate(datas) #:nodoc:
      ema( datas, @sc )
    end
  end

  #===ボリンジャーバンド
  class BollingerBands < RangeSignal
    #====コンストラクタ
    #range:: 集計期間
    #pivot:: ピボット
    def initialize( range=25, pivot=[0,1,2], &block )
      super(range)
      @pivot = pivot
      @block = block
    end
    def calculate(datas) #:nodoc:
      bollinger_bands( datas, @pivot, &@block )
    end
  end

  #===傾き
  class Momentum < RangeSignal
    def calculate(datas) #:nodoc:
      momentum( datas )
    end
  end

  #===傾き(最小二乗法を利用)
  class Vector < RangeSignal
    def calculate(datas)
      vector( datas )
    end
  end

  #===MACD
  class MACD < RangeSignal
    #====コンストラクタ
    #short_range:: 短期EMAの集計期間
    #long_range:: 長期EMAの集計期間
    #signal_range:: シグナルの集計期間
    #smoothing_coefficient:: 平滑化係数
    def initialize( short_range=12, long_range=26,
        signal_range=9, smoothing_coefficient=0.1 )
      raise "illegal arguments." if short_range > long_range
      super(long_range)
      @short_range = short_range
      @smoothing_coefficient = smoothing_coefficient
      @signal = ExponentialMovingAverage.new(
        signal_range, smoothing_coefficient )
    end
    def next_data( data ) #:nodoc:
      macd = super
      return nil unless macd
      signal = @signal.next_data( macd )
      return nil unless signal
      return { :macd=>macd, :signal=>signal }
    end
    def calculate(datas) #:nodoc:
      macd( datas, @short_range, range, @smoothing_coefficient )
    end
  end

  #===RSI
  class RSI < RangeSignal
    #====コンストラクタ
    #range:: 集計期間
    def initialize( range=14 )
      super(range)
    end
    def calculate(datas) #:nodoc:
      rsi( datas )
    end
  end

  #===DMI
  class DMI < RangeSignal
    #====コンストラクタ
    #range:: 集計期間
    def initialize( range=14 )
      super(range)
      @dxs = []
    end
    def calculate(datas) #:nodoc:
      dmi = dmi( datas )
      return nil unless dmi
      @dxs.push dmi[:dx]
      @dxs.shift if @dxs.length > range
      return nil if @dxs.length != range
       dmi[:adx] = ma( @dxs )
      return dmi
    end
  end

  #===ROC
  class ROC < RangeSignal
    #====コンストラクタ
    #range:: 集計期間
    def initialize( range=14 )
      super(range)
    end
    def calculate(datas) #:nodoc:
      roc( datas )
    end
  end

module_function

  #===移動平均値を計算します。
  #datas:: 値の配列。
  #戻り値:: 移動平均値
  def ma( datas )
    total = datas.inject {|t,s|
      t += s; t
    }
    return total / datas.length
  end

  #===加重移動平均値を計算します。
  #datas:: 値の配列。
  #戻り値:: 加重移動平均値
  def wma( datas )
    weight = 1
    total = datas.inject(0.0) {|t,s|
      t += s * weight
      weight += 1
      t
    }
    return total / ( datas.length * (datas.length+1)  /2 )
  end

  #===指数移動平均値を計算します。
  #datas:: 値の配列。
  #smoothing_coefficient:: 平滑化係数
  #戻り値:: 加重移動平均値
  def ema( datas, smoothing_coefficient=0.1 )
    datas[1..-1].inject( datas[0] ) {|t,s|
      t + smoothing_coefficient * (s - t)
    }
  end

  #
  #===ボリンジャーバンドを計算します。
  #
  # +2σ＝移動平均＋標準偏差×2
  # +σ＝移動平均＋標準偏差
  # -σ＝移動平均-標準偏差
  # -2σ＝移動平均-標準偏差×2
  # 標準偏差＝√((各値-値の期間中平均値)の2乗を期間分全部加えたもの)/ 期間
  # (√は式全体にかかる)
  #
  #datas:: 値の配列
  #pivot:: 標準偏差の倍数。初期値[0,1,2]
  #block:: 移動平均を算出するロジック。指定がなければ移動平均を使う。
  #戻り値:: ボリンジャーバンドの各値の配列。例)  [+2σ, +1σ, TP, -1σ, -2σ]
  #
  def bollinger_bands( datas, pivot=[0,1,2], &block )
    ma = block_given? ? yield( datas ) : ma( datas )
    total = datas.inject(0.0) {|t,s|
      t+= ( s - ma ) ** 2
      t
    }
    sd = Math.sqrt(total / datas.length)
    res = []
    pivot.each { |r|
      res.unshift( ma + sd * r )
      res.push( ma + sd * r * -1 ) if r != 0
    }
    return res
  end

  #===一定期間の値の傾きを計算します。
  #datas::  値の配列
  #戻り値:: 傾き。0より大きければ上向き。小さければ下向き。
  def momentum( datas )
      (datas.last - datas.first) / datas.length
  end

  #===最小二乗法で、一定期間の値の傾きを計算します。
  #datas::  値の配列
  #戻り値:: 傾き。0より大きければ上向き。小さければ下向き。
  def vector( datas )
    # 最小二乗法を使う。
    total = {:x=>0.0,:y=>0.0,:xx=>0.0,:xy=>0.0,:yy=>0.0}
    datas.each_index {|i|
      total[:x] += i
      total[:y] += datas[i]
      total[:xx] += i*i
      total[:xy] += i*datas[i]
      total[:yy] += datas[i] * datas[i]
    }
    n = datas.length
    d = total[:xy]
    c = total[:y]
    e = total[:x]
    b = total[:xx]
    return (n*d - c*e) / (n*b - e*e)
  end

  #===MACDを計算します。
  #MACD = 短期(short_range日)の指数移動平均 - 長期(long_range日)の指数移動平均
  #datas::  値の配列
  #smoothing_coefficient:: 平滑化係数
  #戻り値:: macd値
  def macd( datas, short_range, long_range, smoothing_coefficient )
    ema( datas[ short_range*-1 .. -1], smoothing_coefficient ) \
      - ema( datas[ long_range*-1 .. -1], smoothing_coefficient )
  end

  #===RSIを計算します。
  #RSI = n日間の値上がり幅合計 / (n日間の値上がり幅合計 + n日間の値下がり幅合計) * 100
  #nとして、14や9を使うのが、一般的。30以下では売られすぎ70以上では買われすぎの水準。
  #
  #datas::  値の配列
  #戻り値:: RSI値
  def rsi( datas )
    prev = nil
    tmp = datas.inject( [0.0,0.0] ) {|r,i|
      r[ i > prev ? 0 : 1 ] += (i - prev).abs if prev
      prev = i
      r
    }
    (tmp[0] + tmp[1] ) == 0 ? 0.0 : tmp[0] / (tmp[0] + tmp[1]) * 100
  end

  #===DMIを計算します。 
  #  
  # 高値更新  ...  前日高値より当日高値が高かった時その差
  # 安値更新  ...  前日安値より当日安値が安かった時その差
  # DM        ...  高値更新が安値更新より大きかった時高値更新の値。逆の場合は０
  # DM        ...  安値更新が高値更新より大きかった時安値更新の値。逆の場合は０
  # TR        ...  次の３つの中で一番大きいもの
  #                  当日高値-当日安値
  #                  当日高値-前日終値
  #                  前日終値-当日安値
  # AV(+DM)   ...  +DMのn日間移動平均値
  # AV(-DM)   ...  -DMのn日間移動平均値
  # AV(TR)    ...  TRのn日間移動平均値
  # +DI       ...  AV(+DM)/AV(TR)
  # -DI       ...  AV(-DM)/AV(TR)
  # DX        ...  (+DIと-DIの差額) / (+DIと-DIの合計)
  # ADX       ...  DXのn日平均値
  #
  #datas::  値の配列(4本値を指定すること!)
  #戻り値:: {:pdi=pdi, :mdi=mdi, :dx=dx }
  def dmi( datas )
    prev = nil
    tmp = datas.inject( [[],[],[]] ) {|r,i|
      if prev
        dm = _dmi( i, prev )
        r[0] << dm[0] # TR
        r[1] << dm[1] # +DM
        r[2] << dm[2] # -DM
      end
      prev = i
      r
    }
    atr = ma( tmp[0] )
    pdi = ma( tmp[1] ) / atr * 100
    mdi = ma( tmp[2] ) / atr * 100
    dx  = ( pdi-mdi ).abs / ( pdi+mdi )  * 100
    return {:pdi=>pdi, :mdi=>mdi, :dx=>dx }
  end

  #TR,+DM,-DMを計算します。
  #戻り値:: [ tr, +DM, -DM ]
  def _dmi( rate, rate_prev ) #:nodoc:
    pdm = rate.max > rate_prev.max ? rate.max - rate_prev.max : 0
    mdm = rate.min < rate_prev.min ? rate_prev.min - rate.min : 0

    if ( pdm > mdm )
      mdm = 0
    elsif ( pdm < mdm )
      pdm = 0
    end

    a = rate.max - rate.min
    b = rate.max - rate_prev.end
    c = rate_prev.end - rate.min
    tr = [a,b,c].max

    return [tr, pdm, mdm]
  end

  #===ROCを計算します。
  #Rate of Change。変化率。正なら上げトレンド、負なら下げトレンド。
  #
  #datas::  値の配列
  #戻り値:: 値
  def roc( datas )
    (datas.first - datas.last) / datas.last * 100
  end
end