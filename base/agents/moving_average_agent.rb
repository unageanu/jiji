#
# 移動平均を使うエージェント。
# -ゴールデンクロスで買い。
# -デッドクロスで売り。
#
class MovingAverageAgent < JIJI::PeriodicallyAgent

  # エージェントの説明
  def description
      <<-STR
移動平均を使うエージェントです。
 -ゴールデンクロスで買い&売り建て玉をコミット。
 -デッドクロスで売り&買い建て玉をコミット。
      STR
  end
  
  # エージェントを初期化する。
  def init
    # 移動平均の算出クラス
    # 共有ライブラリのクラスを利用。(JIJI::Agent::Sharedモジュールに定義される。)
    @mvs = [
      JIJI::Agent::Shared::MovingAverage.new(@short),
      JIJI::Agent::Shared::MovingAverage.new(@long)
    ]
    @prev_state = nil
    
    # 移動平均をグラフで表示するためのOutput
    @out = output.get( "移動平均線", :graph, {
      :column_count=>2, # データ数は2
      :graph_type=>:rate, # レートにあわせる形式で表示
      :colors=>["#779999","#557777"] # デフォルトのグラフの色
    } )
  end
  
  # 次のレートを受け取る
  def next_period_rates( rates )

    # 移動平均を計算
    res = @mvs.map{|mv| mv.next_rate( rates[:EURJPY].bid ) }
    
    return if ( !res[0] || !res[1])
    
    # グラフに出力
    @out.put( *res )

    # ゴールデンクロス/デッドクロスを判定 
    state = res[0] > res[1] ? :high : :low
    if ( @prev_state && @prev_state != state ) 
      if state == :high
        # ゴールデンクロス
        # 売り建玉があれば全て決済
        operator.positions.each_pair {|k,p|
          operator.commit(p) if p.sell_or_buy == JIJI::Position::SELL
        }
        # 新規に買い
        operator.buy 1
      else
        # デッドクロス
        # 買い建玉があれば全て決済
        operator.positions.each_pair {|k,p|
          operator.commit(p) if p.sell_or_buy == JIJI::Position::BUY
        }
        # 新規に売り 
        operator.sell 1
      end
    end
    @prev_state = state
  end  
  
  # UIから設定可能なプロパティの一覧を返す。
  def property_infos
    super().concat [
      Property.new( "short", "短期移動平均線", 25, :number ),
      Property.new( "long",  "長期移動平均線", 75, :number )
    ]
  end

end