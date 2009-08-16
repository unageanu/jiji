package fx.chart.ui {

  import flash.display.Sprite;
  import mx.core.*;
  import fx.chart.*;
  import fx.util.*;
  import fx.chart.Chart;

  /**
   * 描画コンテキスト
   */
  public class RenderingContext {

    /**
     * コンストラクタ
     */
    public function RenderingContext(canvas:UIComponent) {
      this.canvas = canvas;

      chartComponent = new UIComponent();
      chartComponent.width = canvas.stage.width;
      chartComponent.height = canvas.stage.height;
      canvas.addChild(chartComponent);

      // ステージ
      this.stage = new Stage(
          canvas.stage.width, canvas.stage.height );

      // レイヤーを作成
      layers = new LayerManager( chartComponent, stage );

    }

    /**
     * キャンバスコンテナ
     */
    public var canvas:UIComponent;

    /**
     * チャートコンポーネント(キャンバスに全面配置されるスプライト)
     */
    public var chartComponent:UIComponent;

    /**
     * レイヤー(チャートコンポーネント上のスプライト)
     */
    public var layers:LayerManager;

    /**
     * ステージ情報
     */
    public var stage:Stage;
  }
}