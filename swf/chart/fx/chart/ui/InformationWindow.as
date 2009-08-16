package fx.chart.ui {

  import fx.chart.model.*;
  import fx.chart.ctrl.*;
  import fx.chart.*;
  import fx.util.*;
  import flash.events.*;
  import flash.display.*;
  import flash.text.*;
  import flash.geom.*;
  import flash.filters.*;

  public class InformationWindow extends AbstractChartUI  {


    private static const WIDTH:int = 214;
    private static const HEIGHT:int = 140;

    /**ウインドウ*/
    private var window:Window;
    private var infoLayer:Sprite;

    /**テキストフィールド*/
    private var textFields:Object = new Object();

    /**アイコン*/
    private var up:Bitmap;
    private var down:Bitmap;

    public function InformationWindow( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      infoLayer = new Sprite();
      infoLayer.name = "info";
      rc.layers.window.addChild( infoLayer );

      window = new Window( model,controller,rc,
          infoLayer, WIDTH, HEIGHT);

      var stageWidth:int = rc.stage.width;
      var stageHeight:int = rc.stage.height;

      var g:Graphics = window.window.graphics
      g.lineStyle( 0, 0xD3D3D0, 1,
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      g.moveTo( 10, 64 );
      g.lineTo( 135, 64 );
      g.moveTo( 10, 95 );
      g.lineTo( 135, 95 );
      g.moveTo( 146, 10 );
      g.lineTo( 146, 130 );

      // 最初は非表示
      window.window.visible = false;

      //
      textFields["rate_start"] = createTextField( 11,7,130,32,Constants.TEXT_FORMAT_INFO_RATE_START );
      textFields["rate_end"]   = createTextField( 10,40,130,20,Constants.TEXT_FORMAT_INFO_RATE_END );

      (["max","min","diff"]).forEach( function( item:*,i:int,arr:Array ):void{
        textFields[item + "_value"] = createTextField( 153,21+i*29,70,15,Constants.TEXT_FORMAT_INFO_BASIC_L );
        textFields[item + "_value"].text = "-";
      } );
      ([new Constants.ICON_MAX_LABEL(),
        new Constants.ICON_MIN_LABEL(),
        new Constants.ICON_DIFF_LABEL()]).forEach( function( item:*,i:int,arr:Array ):void{
        item.x = 153;
        item.y = 11+i*29;
        window.window.addChild( item );
      });


      (["x","y"]).forEach( function( item:*,i:int,arr:Array ):void{
        textFields[item] = createTextField( 10,65+i*13,130,15,Constants.TEXT_FORMAT_INFO_BASIC );
      } );

      (["fixed","unfixed"]).forEach( function( item:*,i:int,arr:Array ):void{
        textFields[item] = createTextField( 60,99+i*15,80,16,Constants.TEXT_FORMAT_INFO_BASIC );
      } );

      down = new Constants.ICON_DOWN();
      up = new Constants.ICON_UP();
      ([down,up]).forEach( function( item:*,i:int,arr:Array ):void{
        //item.filters = [new DropShadowFilter( 3.0, 45, 0x888885, 0.5)];
        item.x = 9;
        item.y = 9;
        item.alpha = 0.85;
        window.window.addChild( item );
        item.visible = false;
      });

      var fix:Bitmap = new Constants.ICON_FIXED();
      var unfix:Bitmap = new Constants.ICON_UNFIXED();
      ([fix,unfix]).forEach( function( item:*,i:int,arr:Array ):void{
        item.x = 11;
        item.y = 101+i*16;
        window.window.addChild( item );
      } );
    }
    public function setPosition( x:int, y:int ):void {
        var stageWidth:int = rc.stage.width;
        var stageHeight:int = rc.stage.height;
        if ( model.rateDatas &&
            x >= rc.stage.candle.left+1 &&
            x < rc.stage.candle.right &&
            y > rc.stage.candle.top &&
            y <= rc.stage.profit.bottom ) {
    
          window.window.visible = true;
    
          infoLayer.x = x > rc.stage.candle.right - WIDTH -10 ? x-15-WIDTH : x+15;
          infoLayer.y = y > rc.stage.profit.bottom - HEIGHT -10 ? y-15-HEIGHT : y+15;
    
          var daten:Number = model.positionManager.toDate(x-rc.stage.candle.left-2);
          daten = Math.ceil( daten / model.scaleTime ) * model.scaleTime;
    
          // x,y
          var date:Date = new Date();
          date.setTime( daten*1000 );
          textFields["x"].text = Util.formatDate( date );
          if ( y < rc.stage.candle.bottom ) {
            var rate:Number = model.positionManager.toRate(
                rc.stage.candle.bottom - y, rc.stage.candle.height);
            var l:int = 5 - (rate == 0 ? 1 : Math.log(rate)*Math.LOG10E);
            textFields["y"].text = rate.toFixed(l);
          } else if ( y > rc.stage.profit.top ) {
            var profit:Number = model.positionManager.toProfit(
                rc.stage.profit.bottom - y, rc.stage.profit.height);
            textFields["y"].text = Math.ceil(profit/100)*100;
          } else {
            textFields["y"].text = "-";
          }
    
          // レート
          updateRate( daten );
    
          // 収益
          updateProfit(daten);
    
        } else {
          window.window.visible = false;
        }
    }
    
    public function onMouseMove( ev:MouseEvent ):void {
        setPosition(ev.stageX, ev.stageY)
    }
    private function updateRate( date:Number ):void {
      if ( model.rateDatas ) {
        var d:Array = model.rateDatas.getDataByDate( date );
        if (d) {
          var size:int = d[0] == 0 ? 1 : Math.ceil( Math.log(d[0])*Math.LOG10E );
          var l:int = 5 - ( size <= 0 ? 1 : size ) ;
          textFields["rate_start"].text = d[0].toFixed(l);
          textFields["rate_end"].text = d[1].toFixed(l);

          textFields["max_value"].text = d[2].toFixed(l);
          textFields["min_value"].text = d[3].toFixed(l);
          textFields["diff_value"].text = (d[2]-d[3]).toFixed(l);

          if ( d[0]-d[1] > 0 ) {
            down.visible=true;
            up.visible=false;
          } else {
            down.visible=false;
            up.visible=true;
          }

          return;
        }
      }
      textFields["rate_start"].text = "-";
      textFields["rate_end"].text = "-";

      textFields["max_value"].text = "-";
      textFields["min_value"].text = "-";
      textFields["diff_value"].text = "-";

      down.visible=false;
      up.visible=false;
    }

    private function updateProfit( date:Number ):void {
      if ( model.profitDatas ) {
        var profit:Array = model.profitDatas.getDataByDate( date );
        if (profit) {
          textFields["unfixed"].text = int(profit[0]);
          updateProfitColor( int(profit[0]), textFields["unfixed"] );
          textFields["fixed"].text = int(profit[1]);
          updateProfitColor( int(profit[1]), textFields["fixed"] );
          return;
        }
      }
      textFields["fixed"].text = "-";
      updateProfitColor( 0, textFields["fixed"] );
      textFields["unfixed"].text = "-";
      updateProfitColor( 0, textFields["unfixed"] );
    }
    private function updateProfitColor( profit:Number, text:TextField ):void {
      var f:TextFormat = null;
      if (profit > 0) {
        f = Constants.TEXT_FORMAT_INFO_PROFIT_UP;
      } else if (profit < 0) {
        f = Constants.TEXT_FORMAT_INFO_PROFIT_DOWN;
      } else {
        f = Constants.TEXT_FORMAT_INFO_PROFIT_DRAW;
      }
      text.setTextFormat( f );
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