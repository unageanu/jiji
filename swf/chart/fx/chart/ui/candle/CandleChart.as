package fx.chart.ui.candle {

  import fx.util.*;
  import fx.chart.Chart;
  import fx.chart.ui.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;
  import flash.display.*;
  import flash.text.*;
  import flash.geom.*;
  import flash.external.*;

  /**
   * ローソク足チャート
   */
  public class CandleChart extends AbstractDrawChartUI {

    private var elements:Array;

    /**
     * コンストラクタ
     */
    public function CandleChart(model:Model,
        controller:Controller, rc:RenderingContext) {
      super( model,controller,rc );

      elements = [ 
          new Axis(   model,controller,rc,main,axis,axisY,lowAxis,lowAxisY ),
          new Candle( model,controller,rc,main,axis,axisY,lowAxis,lowAxisY ) ];
    }

    public function onCandleDataChanged( ev:Event ):void {

      // データ数から、各データあたりの幅を算出
      var graphWidth:Number = rc.stage.candle.width;
      var graphHeight:Number = rc.stage.candle.height;


      // レイヤーを初期化
      ([main, axis,axisY,lowAxis,lowAxisY]).forEach( function(l:*,i:*,arr:Array):void{
          l.x = 0;
          Util.clear( l );
      } );
      
      var ctrl:Rectangle = rc.stage.ctrl;
      var candle:Rectangle = rc.stage.candle;
      var trade:Rectangle = rc.stage.trade;
      var xAxis:Rectangle = rc.stage.xAxis;
      var profit:Rectangle = rc.stage.profit;

      // 軸の線を描画
      var g:Graphics = axis.graphics;
      var gb:Graphics = lowAxis.graphics;

      // 軸
      g.lineStyle( 0, Constants.COLOR_AXIS_HI );
      g.moveTo( candle.left+1, candle.top);
      g.lineTo( candle.left+1, profit.bottom-1 );
      g.moveTo( candle.left+1, xAxis.top+1 );
      g.lineTo( candle.right,  xAxis.top+1);

      g.lineStyle( 0, Constants.COLOR_AXIS );
      g.moveTo( candle.left, candle.top);
      g.lineTo( candle.left, profit.bottom );
      g.moveTo( candle.left, xAxis.top );
      g.lineTo( candle.right,  xAxis.top);
      
      if ( model.rateDatas.getDatas().length <= 0 ) { return; }

      for (var i:int=0; i < elements.length; i++) {
        elements[i].init();
      }
      var datas:Array = model.rateDatas.getDatas();
      for (var j:int=0; j < datas.length; j++) {
        for (i=0; i < elements.length; i++) {
          elements[i].drawCandle( datas[j] );
        }
      }
    }
  }
}