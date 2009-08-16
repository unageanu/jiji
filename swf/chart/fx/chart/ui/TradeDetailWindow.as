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

  public class TradeDetailWindow extends AbstractChartUI  {

    private static const WIDTH:int = 230;
    private static const HEIGHT:int = 117;

    private var infoLayer:Sprite;
    private var window:Window;

    /**テキストフィールド*/
    private var textFields:Object = new Object();

    /**アイコン*/
    private var sell:Bitmap;
    private var buy:Bitmap;

    public function TradeDetailWindow( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      infoLayer = new Sprite();
      infoLayer.name = "trade";
      rc.layers.window.addChild( infoLayer );
      window = new Window( model,controller,rc,
          infoLayer, WIDTH, HEIGHT );

      var stageWidth:int = rc.stage.width;
      var stageHeight:int = rc.stage.height;

      var g:Graphics = window.window.graphics;

      g.lineStyle( 0, 0xD3D3D0, 1,
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      g.moveTo( 10, 35 );
      g.lineTo( WIDTH-10, 35 );
      g.moveTo( 10, 77 );
      g.lineTo( WIDTH-10, 75 );

      // 最初は非表示
      infoLayer.visible = false;

      textFields["result"] = createTextField( 10,5,220,24,Constants.TEXT_FORMAT_TINFO_PROFIT_UP );
      textFields["info"] = createTextField( 40,40,180,15,Constants.TEXT_FORMAT_TINFO_INFO );
      textFields["trader"] = createTextField( 10,57,180,15,Constants.TEXT_FORMAT_INFO_BASIC_L  );
      (["start","end"]).forEach( function( item:*,i:int,arr:Array ):void{
        textFields[item] = createTextField( 40,80+i*15,190,15,Constants.TEXT_FORMAT_INFO_BASIC_L );
      } );

      sell = new Constants.ICON_SELL();
      buy = new Constants.ICON_BUY();
      ([sell,buy]).forEach( function( item:*,i:int,arr:Array ):void{
        item.x = 10;
        item.y = 40;
        //item.alpha = 5;
        window.window.addChild( item );
        item.visible = false;
      });

      var start:Bitmap = new Constants.ICON_START_LABEL();
      var end:Bitmap = new Constants.ICON_END_LABEL();
      ([start,end]).forEach( function( item:*,i:int,arr:Array ):void{
        item.x = 11;
        item.y = 82+i*15;
        window.window.addChild( item );
      } );

      // イベントをキャプチャ
      infoLayer.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }

    public function onMouseMove( ev:MouseEvent ):void {
      var stageWidth:int = rc.stage.width;
      var stageHeight:int = rc.stage.height;
      if ( model.rateDatas &&
          ev.stageX >= rc.stage.candle.left+1 &&
          ev.stageX < rc.stage.candle.right &&
          ev.stageY > rc.stage.candle.top &&
          ev.stageY <= rc.stage.profit.bottom ) {
        infoLayer.x = ev.stageX > rc.stage.candle.right - WIDTH -10 ? ev.stageX-15-WIDTH : ev.stageX+15;
        infoLayer.y = ev.stageY > rc.stage.profit.bottom - HEIGHT -10 ? ev.stageY-15-HEIGHT : ev.stageY+15;
      }
    }

    public function update( d:Object, ev:MouseEvent ):void {

      onMouseMove( ev );

      if ( d["profit_or_loss"] > 0 ) {
        textFields["result"].text = "+" + d["profit_or_loss"];
        textFields["result"].setTextFormat( Constants.TEXT_FORMAT_TINFO_PROFIT_UP );
      } else {
        textFields["result"].text = d["profit_or_loss"];
        textFields["result"].setTextFormat( d["profit_or_loss"] == 0
            ? Constants.TEXT_FORMAT_TINFO_PROFIT_DRAW
            : Constants.TEXT_FORMAT_TINFO_PROFIT_DOWN);
      }
      if ( d["sell_or_buy"] == "sell" ) {
        sell.visible = true;
        buy.visible = false;
      } else {
        sell.visible = false;
        buy.visible = true;
      }
      textFields["trader"].text = d["trader"] ? d["trader"] : "-";
      textFields["info"].text = " / " + d["pair"] + " / " + int( d["price"] / d["rate"]);
      textFields["start"].text = d["rate"] + " " + formatDate( d["date"] );
      if ( d["fix_rate"] && d["fix_date"] ) {
        textFields["end"].text = d["fix_rate"] + " " + formatDate( d["fix_date"] );
      } else {
        textFields["end"].text = "-";
      }
    }

    private function formatDate( longtime:Number ):String {
      var date:Date = new Date();
      date.setTime( longtime*1000 );
      return Util.formatDate( date );
    }

    private function createTextField( x:int, y:int,
        width:int, height:int, format:TextFormat ):TextField {
      var text:TextField = new TextField();
      text.selectable = false;
      text.width = width;
      text.height = height;
      text.defaultTextFormat = format;
      text.y = y;
      text.x = x;
      text.text = "-";
      window.window.addChild( text );
      return text;
    }

  }

}