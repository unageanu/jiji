
#===ポジションマネージャ
#以下の機能を提供するユーティリティクラスです。
#-  条件にマッチするポジションを探す。
#-  すべてのor条件にマッチするポジションを決済する。
#-  指定したポジションを損切りorトレーリングストップで決済する。
class PositionManager
  include Enumerable
  
  #====コンストラクタ
  #operator:: オペレータ
  def initialize( operator )
    raise "illegal argument." unless operator
    @operator = operator
    @marked = {}
  end

  #====ポジションを列挙します。
  def each( &block )
    @operator.positions.each_pair {|k,v|
      yield v
    }
  end

  #====条件にマッチするポジションを決済します。
  #&block:: 決済するポジションを判定するブロック。JIJI::Positionが引数として渡され、trueが返された場合決済されます。
  def commit_by
    each {|p|
      @operator.commit( p ) if yield p
    }
  end

  #====すべてのポジションを決済します。
  def commit_all
    commit_by{|p| true }
  end

  #====現在保有しているポジションの損益合計を取得します。
  #※決済済みポジションの損益は含まれません。
  #戻り値:: 現在保有しているポジションの損益合計
  def total_profit_or_loss
    inject(0.0) {|t, p|
      t += p.profit_or_loss
    }
  end

  #====ポジションに損切りロジックを登録します。
  #損切りロジックが登録されたポジションはcheckが実行される度に損益がチェックされ、
  #PositionManager::StopStrategy.close?がtrueになれば決済されます。
  #1つのポジションに対して複数のロジックを設定可能。いずれかのロジックがtrueを返せば損切りされます。
  #position_id:: ポジションID
  #stop_strategy:: 損切りルール(PositionManager::StopStrategy)
  def register( position_id, stop_strategy )
    @marked[position_id] ||= []
    @marked[position_id] << stop_strategy
  end

  #====ポジションをロスカットの対象としてマークします。
  #マークされたポジションはcheckが実行される度に損益がチェックされ、
  #損失がdissipationで設定した値以下になっていれば決済されます。
  #
  #position_id:: ポジションID
  #dissipation:: 許容しうる損失
  def register_loss_cut( position_id, dissipation )
    register(position_id,LossCut.new( dissipation ))
  end

  #====ポジションをトレーリングストップの対象としてマークします。
  #マークされたポジションはcheckが実行される度に損益がチェックされ、
  #「今までの最高損益-現在の損益」がdissipationで設定した値以下になっていれば決済されます。
  #
  #position_id:: ポジションID
  #dissipation:: 許容しうる損失
  def register_trailing_stop( position_id, dissipation )
    register(position_id,TrailingStop.new( dissipation ))
  end

  #====ポジションに損切りロジックが登録されているかどうか評価します。
  #position_id:: ポジションID
  #return:: 損切りの対象であればtrue
  def registered?( position_id )
    @marked.key?(position_id)
  end

  #====ポジションに登録されている損切りロジックの一覧を取得します。
  #position_id:: ポジションID
  #return:: ポジションに登録されている損切りロジックの配列
  def get_registered_strategy( position_id )
    @marked[position_id] || []
  end

  #====ポジションに登録された損切りロジックを解除します。
  #position_id:: ポジションID
  #strategy:: 削除する損切りロジック
  def unregister(position_id, strategy)
    list = get_registered_strategy(position_id)
    list.delete(strategy)
  end

  #====ポジションに登録された損切りロジックを全て解除します。
  #position_id:: ポジションID
  def unregister_all(position_id)
    @marked.delete( position_id )
  end


  #====監視対象のポジションが閾値を越えていないかチェックし、必要があれば決済します。
  #定期的に実行してください。
  #戻り値:: 決済したポジションの配列
  def check
    commited = []
    @marked.each_pair {|k,v|
      p = @operator.positions[k]
      if !p || p.state != JIJI::Position::STATE_START
        @marked.delete p.position_id
      else
        v.each {|strategy|
          next unless strategy.close?(p)
          @operator.commit( p )
          commited << p
          unregister_all( p.position_id )
          break
        }
      end
    }
    commited
  end

  #===手じまい戦略
  module StopStrategy
    #====決済すべきか評価する。
    #position:: ポジション(JIJI::Position)
    def close?(position)
      return false
    end
  end
  #===トレーリングストップ
  class TrailingStop
    include StopStrategy
    def initialize( dissipation )
      @dissipation=dissipation
    end
    def close?(position)
      @max=0 if !@max
      result = (@max - position.profit_or_loss)*-1 <= @dissipation
      @max = [position.profit_or_loss, @max].max
      return result
    end
  end
  #===ロスカット
  class LossCut
    include StopStrategy
    def initialize( dissipation )
      @dissipation=dissipation
    end
    def close?(position)
      position.profit_or_loss <= @dissipation
    end
  end
end
