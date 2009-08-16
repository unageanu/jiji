package fx.chart.ui {

  import flash.geom.*;

  public class Stage {

    /** パディング */
    public static const PADDING:Number = 10;
    /** 左パディング */
    public static const PADDING_LEFT:Number = 59;

    /** コントローラー */
    public static const CONTROLLER:Number = 30;
    /** グラフ表示領域 */
    public static const GRAPH:Number = 80;
    /** トレード結果表示領域 */
    public static const TRADE:Number = 40;
    /** X軸 */
    public static const X_AXIS:Number = 15;
    /** 損益結果表示領域 */
    public static const PROFIT:Number = 80;

    /**
     * ステージの幅
     */
    public var width:int;
    /**
     * ステージの高さ
     */
    public var height:int;

    /**
     * コントロール
     */
    public var ctrl:Rectangle;
    /**
     * ローソク足
     */
    public var candle:Rectangle;
    /**
     * グラフ
     */
    public var graph:Rectangle;
    /**
     * 取引結果
     */
    public var trade:Rectangle;
    /**
     * X軸
     */
    public var xAxis:Rectangle;
    /**
     * 収益
     */
    public var profit:Rectangle;

    /**
     * コンストラクタ
     */
    public function Stage( width:int, height:int ) {
      this.width = width;
      this.height = height;
      ctrl = new Rectangle(
          PADDING,
          PADDING,
          width - PADDING - PADDING,
          CONTROLLER );
      candle = new Rectangle(
          PADDING_LEFT,
          PADDING+CONTROLLER,
          width - PADDING - PADDING_LEFT,
          height - (PADDING+PROFIT+X_AXIS+GRAPH+PADDING+CONTROLLER) );
      graph = new Rectangle(
          PADDING_LEFT,
          height - (PADDING+PROFIT+X_AXIS+GRAPH) ,
          width - PADDING - PADDING_LEFT,
          GRAPH  );
      xAxis = new Rectangle(
          PADDING_LEFT,
          height - (PADDING+PROFIT+X_AXIS),
          width - PADDING - PADDING_LEFT,
          X_AXIS );
      profit = new Rectangle(
          PADDING_LEFT,
          height - (PADDING+PROFIT ),
          width - PADDING - PADDING_LEFT,
          PROFIT );
      trade = new Rectangle(
          PADDING_LEFT,
          height - (PADDING+PROFIT ),
          width - PADDING - PADDING_LEFT,
          PROFIT );
    }

  }

}