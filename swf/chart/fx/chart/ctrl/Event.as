package fx.chart.ctrl {

  import flash.events.*;
  import fx.chart.model.*;

  /**
   * イベント
   */
  public class Event extends flash.events.Event {

    /**
     * ローソク足データがリロードされた
     */
    public static const CANDLE_DATA_CHANGED:String = "CANDLE_DATA_CHANGED";

    /**
     * トレードデータがリロードされた
     */
    public static const TRADE_DATA_CHANGED:String = "TRADE_DATA_CHANGED";

    /**
     * 損益データがリロードされた
     */
    public static const PROFIT_DATA_CHANGED:String = "PROFIT_DATA_CHANGED";

    /**
     * アウトプットデータがリロードされた
     */
    public static const OUTPUT_DATA_CHANGED:String = "OUTPUT_DATA_CHANGED";

    /**
     * プロセスIDが更新された
     */
    public static const PROCESS_ID_CHANGED:String = "PROCESS_ID_CHANGED";
    /**
     * スケールが更新された
     */
    public static const SCALE_CHANGED:String = "SCALE_CHANGED";

    /**
     * 範囲が更新された
     */
    public static const RANGE_CHANGED:String = "RANGE_CHANGED";

    /**
     * 表示時刻が更新された
     */
    public static const DATE_CHANGED:String = "DATE_CHANGED";

    /**
     * 出力データ一覧が更新された
     */
    public static const OUTPUT_LIST_CHANGED:String = "OUTPUT_LIST_CHANGED";

    
    /**
     * リクエストが開始/終了された
     */
    public static const REQUEST_COUNT_CHANGED:String = "REQUEST_COUNT_CHANGED";
    
    /**
     * モデル
     */
    public var model:Model;

    /**
     * コンストラクタ
     */
    public function Event(type:String, model:Model,
      bubbles:Boolean=false, cancelable:Boolean = false) {
      super( type, bubbles, cancelable );
      this.model = model;
    }
  }
}