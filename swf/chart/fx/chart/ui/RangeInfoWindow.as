package fx.chart.ui {

  import fx.chart.model.*;
  import fx.chart.ctrl.Controller;
  import fx.chart.*;
  import fx.util.*;
  import flash.events.*;
  import flash.display.*;
  import flash.text.*;
  import flash.geom.*;
  import flash.filters.*;

  public class RangeInfoWindow extends AbstractChartUI  {

    private static const WIDTH:int = 170;
    private static const HEIGHT:int = 45;

    private var infoLayer:Sprite;
    private var window:Window;

    /**テキストフィールド*/
    private var textFields:Object = new Object();

    /**アイコン*/
    private var sell:Bitmap;
    private var buy:Bitmap;

    public function RangeInfoWindow( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      infoLayer = new Sprite();
      infoLayer.name = "range";
      rc.layers.window.addChild( infoLayer );
      window = new Window( model,controller,rc,
          infoLayer, WIDTH, HEIGHT );

      var stageWidth:int = rc.stage.width;
      var stageHeight:int = rc.stage.height;


      // 最初は非表示
      infoLayer.visible = false;

      textFields["info"] = createTextField( 25,10,220,30,Constants.TEXT_FORMAT_PINFO );

      var handle:Bitmap = new Constants.ICON_SCROLL_INFO_HANDLE();
      handle.x = 10;
      handle.y = 10;
      handle.alpha = 90;
      window.window.addChild( handle );

      infoLayer.y = rc.stage.ctrl.top + 20;
      infoLayer.x = rc.stage.ctrl.left;
    }

    public function update( start:Number, end:Number, x:Number ):void {
      //infoLayer.x = x  x+30;
      textFields["info"].text = formatDate(start) + "\n - " + formatDate(end);
    }

    private function formatDate( longtime:Number ):String {
      var date:Date = new Date();
      date.setTime( longtime*1000 );
      return Util.formatDate( date, "YYYY/MM/DD JJ:NN" );
    }

    private function createTextField( x:int, y:int,
        width:int, height:int, format:TextFormat ):TextField {
      var text:TextField = new TextField();
      text.selectable = false;
      text.width = width;
      //text.height = height;
      text.defaultTextFormat = format;
      text.y = y;
      text.x = x;
      text.text = "-";
      window.window.addChild( text );
      return text;
    }

  }

}