package fx.chart.ui {

  import flash.display.*;
  import mx.core.*;
  import fx.chart.*;
  import fx.chart.ctrl.*;
  import fx.chart.model.*;
  import fx.util.*;

  /**
   * チャートUIの抽象基底クラス
   */
  public class AbstractDrawChartUI extends AbstractChartUI {

    /**スプライト*/
    protected var main:Sprite;
    protected var axis:Sprite;
    protected var lowAxis:Sprite;
    protected var axisY:Sprite;
    protected var lowAxisY:Sprite;
    protected var all:Array;

    /**
     * コンストラクタ
     */
    public function AbstractDrawChartUI(model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      // スプライト
      main = new Sprite();
      rc.layers.main.addChild( main );
      axis = new Sprite();
      rc.layers.axis.addChild( axis );
      lowAxis = new Sprite();
      rc.layers.lowAxis.addChild( lowAxis );
      axisY = new Sprite();
      rc.layers.axisY.addChild( axisY );
      lowAxisY = new Sprite();
      rc.layers.lowAxisY.addChild( lowAxisY );

      all = [main,axis,lowAxis,axisY,lowAxisY];
    }

    /**
     * 追加したスプライトを親のスプライトから取り除く。
     */
    public function destroy():void {
      all.forEach( function(item:*,i:int,array:Array):void {
        item.parent.removeChild( item );
      });
    }
    /**
     * スプライトの表示/非表示を切り替える。
     */
    public function setVisible( visible:Boolean ):void {
      all.forEach( function(item:*,i:int,array:Array):void {
        item.visible = visible;
      });
    }
  }

}