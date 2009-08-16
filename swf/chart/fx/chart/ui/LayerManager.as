package fx.chart.ui {

  import flash.events.*;
  import flash.display.*;
  import fx.chart.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;

  /**
   * レイヤーマネージャ
   */
  public class LayerManager {

    public var window:Sprite;
    public var ctrl:Sprite;
    public var main:Sprite;
    public var axis:Sprite;
    public var axisY:Sprite;
    public var pointer:Sprite;
    public var lowAxis:Sprite;
    public var lowAxisY:Sprite;
  
    private var stage:fx.chart.ui.Stage;
    private var chartComponent:Sprite;

    /**
     * コンストラクタ
     */
    public function LayerManager(chartComponent:Sprite, stage:fx.chart.ui.Stage) {
      
      this.chartComponent = chartComponent;
      this.stage = stage;
      
      // レイヤーを作成
      lowAxisY = new Sprite();
      chartComponent.addChild( lowAxisY );

      lowAxis = new Sprite();
      chartComponent.addChild( lowAxis );

      pointer = new Sprite();
      chartComponent.addChild( pointer );

      main = new Sprite();
      chartComponent.addChild( main );

      axisY = new Sprite();
      chartComponent.addChild( axisY );

      axis = new Sprite();
      chartComponent.addChild( axis );

      ctrl = new Sprite();
      chartComponent.addChild( ctrl );

      window = new Sprite();
      chartComponent.addChild( window );

      // マスク
      setChartMask(main);
      setChartMask(axisY);
      setChartMask(lowAxisY);
    }
    
    /**
     * スプライトにチャート領域のみを描画するマスクを設定する。
     * @param target マスクを設定するスプライト
     */
    private function setChartMask( target:Sprite ):void {
      // マスク
      var mask:Sprite = new Sprite();
      mask.graphics.beginFill(0x010101);
      mask.graphics.drawRect( stage.candle.x, stage.candle.y, 
          stage.candle.width, stage.height - fx.chart.ui.Stage.PADDING );
      mask.graphics.endFill();
      mask.alpha = 100;
      this.chartComponent.addChild( mask );

      // circleスプライトのマスクとしてmaskスプライトを設定
      target.mask = mask;
    }
    
    /**
     * showで指定された名前を持つWindowだけ表示する。
     */
    public function setWindowVisible( show:Object ):void {
      for ( var i:int =0; i < window.numChildren; i++ ) {
        var w:DisplayObject = window.getChildAt( i );
        w.visible = show[w.name];
      }
    }

  }

}