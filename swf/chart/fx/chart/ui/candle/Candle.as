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
   * ローソク足
   */
  internal class Candle extends AbstractChartUI  {

    private var main:Sprite;

    public function Candle( model:Model,controller:Controller, rc:RenderingContext,
        main:Sprite, axis:Sprite, axisY:Sprite, lowAxis:Sprite, lowAxisY:Sprite ) {
      super( model,controller,rc );
      this.main = main;
    }

    public function init( ):void {

    }
    public function drawCandle( data:Object ):void {

      var pm:PositionManager = model.positionManager;
      var g:Graphics = main.graphics;

      // 中心位置なので2を引いて蝋の左辺にする
      var x:int = pm.fromDate( data[5] ) + rc.stage.candle.left - 2;

      g.lineStyle( 0, Constants.COLOR_CANDLE, 1, true,
          LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );

      // 蝋
      var up:Boolean = data[1] >= data[0];
      var low:Number  = !up  ? data[1] : data[0];
      var high:Number = up ? data[1] : data[0];

      var height:int = rc.stage.candle.height;

      var y:int = pm.fromRate( high, height ); // int((max - high) * hp );
      var h:int = y - pm.fromRate( low, height );
//      var matr:Matrix = new Matrix();
//      matr.createGradientBox(10, h, Math.PI / 2, 0, y+PADDING);
      g.moveTo( x, rc.stage.candle.bottom - y );
      g.beginFill( up ? Constants.COLOR_ROW_UP_HIGH : Constants.COLOR_ROW_DOWN_LOW, 1.0 );
//      g.beginGradientFill(
//          GradientType.LINEAR,
//          up ? [COLOR_ROW_UP_HIGH, COLOR_ROW_UP_LOW]
//             : [COLOR_ROW_DOWN_HIGH, COLOR_ROW_DOWN_LOW],
//          [1,1],
//          [0x00, 0xFF],
//          matr,
//          SpreadMethod.PAD)
      g.drawRect( x, rc.stage.candle.bottom - y, 4, h );
      g.endFill();

      // 火
      if ( data[2] != high ) {
        var y2:int =  pm.fromRate( data[2], height ); //int((max - data[2]) * hp );
        g.moveTo( x+2, rc.stage.candle.bottom - y2 );
        g.lineTo( x+2, rc.stage.candle.bottom - y );
      }
      if ( data[3] != low ) {
        var y3:int = pm.fromRate( data[3], height ); // int((max - data[3]) * hp );
        g.moveTo( x+2, rc.stage.candle.bottom - (y-h) );
        g.lineTo( x+2, rc.stage.candle.bottom - y3 );
      }
      //x += 2;
    }
  }

}