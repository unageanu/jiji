
# 一定期間の移動平均を得る
class MovingAverage
  def initialize( range=25 )
    @rates = [] # レートを記録するバッファ
    @range = range
  end

  def next_rate( rate )
    # バッファのデータを更新
    @rates.push rate
    @rates.shift if @rates.length > @range
    
    # バッファサイズが十分でなければ、nilを返す。
    return nil if @rates.length != @range
    
    # 移動平均を算出
    return MovingAverage.get_moving_average(@rates)
  end

  # 前の結果(引数で指定した件数だけ記録。)
  attr :prev, true
  
private
  # 移動平均値を計算する。 
  def self.get_moving_average( rates )
    total = 0
    rates.each {|s|
      total += s.end
      total += s.max
      total += s.min
    }
    return total / ( rates.length * 3 )
  end  
end