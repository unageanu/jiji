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
   * 軸
   */
  internal class Axis extends AbstractChartUI {

    /**ローソク足を描画するスプライト*/
    private var axis:Sprite;
    private var lowAxis:Sprite;
    private var axisY:Sprite;
    private var lowAxisY:Sprite;

    public function Axis( model:Model,controller:Controller, rc:RenderingContext,
        main:Sprite, axis:Sprite, axisY:Sprite, lowAxis:Sprite, lowAxisY:Sprite ) {
      super( model,controller,rc );
      this.axis = axis;
      this.lowAxis = lowAxis;
      this.axisY = axisY;
      this.lowAxisY = lowAxisY;
    }

    public function init( ):void {

      var max:Number = model.positionManager.rateMax;
      var min:Number = model.positionManager.rateMin;

      var ctrl:Rectangle = rc.stage.ctrl;
      var candle:Rectangle = rc.stage.candle;
      var trade:Rectangle = rc.stage.trade;
      var xAxis:Rectangle = rc.stage.xAxis;
      var profit:Rectangle = rc.stage.profit;

      // 軸の線を描画
      var gb:Graphics = lowAxis.graphics;

      // y軸メモリ
      gb.lineStyle( 0, Constants.COLOR_AXIS_RIGHT, 1, true,
          LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );

      var diff:Number = max-min;
      var step:Number = Math.pow(0.1, 3-int( max == 0 ? 1 : Math.log(max)*Math.LOG10E) );
      if ((diff / step) > 5) {
        step *= int( diff / step / 5);
      }
      var start:Number = Math.ceil( min / step ) * step;
      for( var tmp:Number=start; tmp<=max; tmp+=step) {
        var y:int = candle.bottom
          - model.positionManager.fromRate(tmp,candle.height);
        gb.moveTo( candle.left, y );
        gb.lineTo( candle.right, y );

        var scaleText:TextField = new TextField();
        scaleText.selectable = false;
        scaleText.text = tmp.toFixed( 4-(max == 0 ? 1 : Math.log(max)*Math.LOG10E) );
        scaleText.width = candle.left-2;
        scaleText.setTextFormat( Constants.TEXT_FORMAT_SCALE_Y );
        scaleText.y = y-8;
        scaleText.x = 0;

        lowAxis.addChild(scaleText);
      }

      // x軸メモリの描画準備
      var sf:ScaleFormatter = new ScaleFormatter( model.scale );
      sf.start( Util.createDate( model.startDate.getTime()/1000 ) );
      start = model.startDate.getTime()/1000;
      var end:Number = model.endDate.getTime()/1000;
      var next:Number = sf.nextDate().getTime()/1000;

      while ( next < end ) {

        var x:int = candle.left +
          model.positionManager.fromDate( next );

        // x軸のメモリを書く
        lowAxisY.graphics.lineStyle( 0, Constants.COLOR_AXIS_RIGHT, 1, true,
            LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );

        var str:String = sf.format( Util.createDate(next) );
        lowAxisY.graphics.moveTo( x, candle.top );
        lowAxisY.graphics.lineTo( x, xAxis.top );
        lowAxisY.graphics.moveTo( x, xAxis.bottom );
        lowAxisY.graphics.lineTo( x, profit.bottom );

        scaleText = new TextField();
        scaleText.selectable = false;
        scaleText.text = str;
        scaleText.width = 100;
        scaleText.setTextFormat( Constants.TEXT_FORMAT_SCALE_X );
        scaleText.y = xAxis.top+0;
        scaleText.x = x-50;

        lowAxisY.addChild(scaleText);

        next = sf.nextDate().getTime()/1000;
      }
    }
    public function drawCandle( data:Object ):void {}
  }

}