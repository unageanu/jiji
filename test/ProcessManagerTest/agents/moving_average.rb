#
# 移動平均を使うエージェント。
# -ゴールデンクロスで買い。
# -デッドクロスで売り。
#
class MovingAverageAgent < JIJI::PeriodicallyAgent
  
  def description
      <<-STR
移動平均を使うエージェント。
 -ゴールデンクロスで買い&売り建て玉をコミット。
 -デッドクロスで売り&買い建て玉をコミット。
      STR
  end  
  
  def init
    logger.debug("start agent")
    @mvs = [MovingAverage.new(short),MovingAverage.new(long)]
    @prev_state = nil
    @out = output.get( "mv", :graph )
  end
  
  # 次のレートを受け取る
  def next_period_rates( rates )
    res = @mvs.map{|mv| mv.next_rate( rates[:EURJPY].bid ) }
    
    return if ( !res[0] || !res[1])
    @out.put( *res ) 
    state = res[0] > res[1] ? :high : :low
    if ( @prev_state && @prev_state != state ) 
      if state == :high
        # ゴールデンクロス
        operator.positions.each_pair {|k,p|
          p.commit if p.sell_or_buy == JIJI::Position::SELL
        }
        operator.buy 1
      else
        # デッドクロス
        operator.positions.each_pair {|k,p|
          p.commit if p.sell_or_buy == JIJI::Position::BUY
        }        
        operator.sell 1
      end
    end
    @prev_state = state
  end  
  
  def property_infos
    super().concat [
      Property.new( "short", "短期移動平均線", 25 ),
      Property.new( "long",  "長期移動平均線", 75 )
    ]
  end
  
private
  attr :short, true
  attr :long,  true
end

# 一定期間の移動平均を得る
class MovingAverage
  def initialize( range=25, prev_size=10  )
    @rates = []
    @range = range
    @prev = []
    @prev_size = prev_size
  end

  def next_rate( rate )
    @rates.push rate
    @rates.shift if @rates.length > @range

    return nil if @rates.length != @range
    a = MovingAverage.get_moving_average(@rates)

    @prev.unshift a
    @prev.pop if @prev.length > @prev_size
    return a
  end

  # 前の結果(引数で指定した件数だけ記録。)
  attr :prev, true
  
private 
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

