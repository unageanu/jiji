package fx.chart.ui {

  import fx.util.*;
  import fx.chart.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;

  import flash.display.*;
  import flash.events.MouseEvent;
  import flash.text.*;
  import flash.geom.*;
  import flash.external.*;

  /**
   * 取引データ
   */
  public class TradeResult extends AbstractDrawChartUI {

    /**詳細情報ウインドウ*/
    private var detailWindow:TradeDetailWindow;

    /**取引結果を描画するスプライト*/
    private var graph:Sprite;
    private var graphFixed:Sprite;
    private var trades:Sprite;

    public function TradeResult( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      detailWindow = new TradeDetailWindow( model,controller,rc );

      // スプライト
      graphFixed = new Sprite();
      rc.layers.lowAxisY.addChild( graphFixed );
      graph = new Sprite();
      rc.layers.main.addChild( graph );
      trades = new Sprite();
      rc.layers.axisY.addChild( trades );
      
    }
    public function onTradeDataChanged( ev:Event ):void {
      trades.x = 0;
      Util.clear( trades );

      var trade:Rectangle = rc.stage.trade;

      var datas:Array = model.tradeDatas.getDatas();
      if ( datas.length <= 0 ) { return; }

      datas.sortOn( "date", Array.NUMERIC ); // 開始日時順にソート
      var slotsUp:Array = [];
      var slotsDown:Array = [];
      for (var i:int=0;i<6;i++) {
         slotsUp.push(new Slot(model.scaleTime));
         slotsDown.push(new Slot(model.scaleTime));
      }
      datas.forEach( function(t:*,i:int,arr:Array):void{
         var slots:Array = t.profit_or_loss >= 0 ? slotsUp : slotsDown 
        for (var j:int=0;j<slots.length;j++) {
          if ( !slots[j].conflict(t) ) {
            slots[j].add(t);
            return;
          }
        }
        // 入りきらないモノは破棄。
      });

      // 描画
      slotsUp.forEach( function(s:*,j:int,arr2:Array):void{
        var y:int = trade.top + int(trade.height/2) - (j+1) * 6;
        drawSlot( s, y );
      });
      slotsDown.forEach( function(s:*,j:int,arr2:Array):void{
          var y:int = trade.top + int(trade.height/2) +2 +  j * 6;
          drawSlot( s, y );
      });
    }
    
    private function drawSlot( s:Slot, y:int ):void {
        
        var trade:Rectangle = rc.stage.trade;
        
        s.data.forEach( function(d:*,i:int,arr:Array):void {
    
          var sprite:Sprite = new Sprite();
          var g:Graphics =sprite.graphics;
    
          var start:int = model.positionManager.fromDate( Math.ceil(d.date / model.scaleTime) * model.scaleTime );
          var end:Number = 0;
          if ( d.fix_date ) {
            end = model.positionManager.fromDate( Math.ceil(d.fix_date / model.scaleTime) * model.scaleTime );
          }
          var w:int = end - start + 4 < trade.width ? end - start + 4 : trade.width ;
          var color:uint = getTradeColor(d);
    
          // 開始円
          var img:Bitmap = null;
          if ( start > 3 ) {
            img = getTradeBitmap( d );
            img.x = 0;
            img.y = 0;
            sprite.addChild(img);
          }
    
          // 線
          var abs:Number = Math.abs( d.profit_or_loss);
          var left:int = NaN;
          if ( d.fix_date && (end+trade.left < trade.right) ) {
            if ( start > 0) {
              left = w-2;
            } else {
              left = end;
            }
          } else {
            if ( start > 0) {
              left = trade.width - start;
            } else {
              left = trade.width-1;
            }
          }
          g.lineStyle( 0, color, 1,
              true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
          g.moveTo( start > 3 ? 2 : 0 , 2 );
          g.lineTo( left, 2 );
    
          // 終了円
          if ( d.fix_date && trade.left + end <= trade.right -3 ) {
            img = getTradeBitmap( d );
            img.x = start > 0 ? w-4 : end-3;
            img.y = 0;
            sprite.addChild(img);
          }
          
          // あたり判定を行うためのスプライト
          var overSpace:Sprite = new Sprite();
          overSpace.alpha = 1;
          overSpace.graphics.beginFill(0x000000);
          overSpace.graphics.drawRect( 0, 0, left+5, 6 );
          overSpace.graphics.endFill();
          overSpace.x = start > 0 ? start+trade.left-2 : trade.left ;
          overSpace.y = y ;
          overSpace.visible = false;
          sprite.hitArea = overSpace;
          
          sprite.x = start > 0 ? start+trade.left-2 : trade.left + 1;
          sprite.y = y ;
          sprite.addEventListener(MouseEvent.MOUSE_OVER, function(ev:flash.events.MouseEvent):void {
            rc.layers.setWindowVisible({"trade":true});
            detailWindow.update( d, ev );
          });
          sprite.addEventListener(MouseEvent.MOUSE_OUT,  function(ev:flash.events.MouseEvent):void {
            rc.layers.setWindowVisible({"info":true});
          });
          trades.addChild( overSpace );
          trades.addChild( sprite );
        });
    }
    
    private function getTradeBitmap(d:Object):Bitmap {
      var sell:Boolean = d["sell_or_buy"] == "sell";
      var img:Bitmap = null;
      if (d.profit_or_loss > 0) {
        img = sell ? new Constants.ICON_TRADE_UP_SELL()
                   : new Constants.ICON_TRADE_UP_BUY();
      } else if (d.profit_or_loss == 0) {
          img = sell ? new Constants.ICON_TRADE_DRAW_SELL()
          : new Constants.ICON_TRADE_DRAW_BUY();
      } else {
        img = sell ? new Constants.ICON_TRADE_DOWN_SELL()
                   : new Constants.ICON_TRADE_DOWN_BUY();
      }
      var abs:Number = Math.abs( d.profit_or_loss);
      return img;
    }
    private function getTradeColor(d:Object):uint {
      var color:uint = 0;
      if (d.profit_or_loss > 0) {
        color = Constants.COLOR_UP;
      } else  if (d.profit_or_loss == 0) {
          color = Constants.COLOR_DRAW;
      } else {
        color = Constants.COLOR_DOWN;
      }
      return color;
    }

    public function onProfitDataChanged( ev:Event ):void {

      // レイヤーを初期化
      ([graph,graphFixed,axis,lowAxis]).forEach( function(l:*,i:*,arr:Array):void{
          l.x = 0;
          Util.clear( l );
      } );

      var pm:PositionManager = model.positionManager;
      var profit:Rectangle = rc.stage.profit;
      var middle:int = profit.top + profit.height/2;

      // 0
      createText( "0", axis,  Constants.TEXT_FORMAT_SCALE_Y,  0, middle-8, profit.left-2 );

      // 背景
//      axis.graphics.lineStyle( 0, Constants.COLOR_AXIS_HI );
//      axis.graphics.moveTo( profit.left+1, middle+1 );
//      axis.graphics.lineTo( profit.right, middle+1 );
      axis.graphics.lineStyle( 0, Constants.COLOR_CANDLE );
      axis.graphics.moveTo( profit.left+1, middle );
      axis.graphics.lineTo( profit.right, middle );
//      var img:Bitmap = new Constants.BITMAP_STRIPE();
//      g.beginBitmapFill(img.bitmapData);
//      g.drawRect( Constants.LEFT+2, middle,
//          stageWidth-Constants.LEFT-Constants.PADDING, 1 );
//      g.endFill();

      if ( model.profitDatas.getDatas().length <= 0 ) { return; }

      // 軸
      lowAxis.graphics.lineStyle( 0, Constants.COLOR_AXIS_RIGHT, 1, true,
          LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );

      var step:Number = Math.pow(10, int(pm.profitPerY == 0 ? 1 : Math.log(pm.profitPerY)*Math.LOG10E));
      if ( pm.profitPerY > step * 5 ) {
        step *= 5;
      }
      var start:Number = Math.ceil( -1*pm.profitPerY / step ) * step;
      for( var tmp:Number=start; tmp<=pm.profitPerY; tmp+=step) {
        if ( tmp == 0 ) { continue; }
        var y:int = profit.bottom
          - pm.fromProfit(tmp,profit.height); //int((max-tmp) * hp);
        lowAxis.graphics.moveTo( rc.stage.candle.left+1, y );
        lowAxis.graphics.lineTo( rc.stage.candle.right, y );

        createText( tmp.toString(), axis,  Constants.TEXT_FORMAT_SCALE_Y,  0, y-8, rc.stage.candle.left-2 );
      }


      // データ
      var datas:Array = model.profitDatas.getDatas();
      graph.graphics.lineStyle( 0, Constants.COLOR_UNFIXED, 1,
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      var prevX:Array = [];
      var prevY:Array = [];
      var imgRed:Bitmap  = new Constants.BITMAP_STRIPE_RED();
      var imgBlue:Bitmap = new Constants.BITMAP_STRIPE_BLUE();
      datas.forEach( function(d:*,i:int,arr:Array):void {
        var x:int = pm.fromDate( d[4] )+profit.left;
        var y:int = profit.bottom - pm.fromProfit( d[0], profit.height );

        // 現在の損益
        if (i==0) {
          graph.graphics.moveTo( x, y);
        } else {
          graph.graphics.lineTo( x, y );
        }

        // コミット済み損益
        y = profit.bottom - pm.fromProfit( d[1], profit.height );//middle - d[1]*hp;
        if ( i <= 0 || i >= datas.length-1 ) {
          prevY.push(y);
          prevX.push(x);
          return;
        }

        if ( prevY[prevY.length-1] != y ) {
          prevY.push(y);
          prevX.push(x);
          if ( prevY[prevY.length-2] >= middle ) {
            if ( y < middle ) {
              drawFixedPosition(graphFixed.graphics,imgBlue,prevX,prevY,middle);
              prevX = [x];
              prevY = [y];
            }
          } else {
            if ( y >= middle ) {
              drawFixedPosition(graphFixed.graphics,imgRed,prevX,prevY,middle);
              prevX = [x];
              prevY = [y];
            }
          }
        }
      });
      drawFixedPosition(graphFixed.graphics,prevY[0]>=middle ? imgBlue : imgRed,prevX,prevY,middle);
    }
    private function drawFixedPosition(g:Graphics,
        img:Bitmap,prevX:Array,prevY:Array,middle:int):void {
      g.moveTo( prevX[0], middle );
      g.beginBitmapFill(img.bitmapData);
      prevY.forEach( function(d:*,i:int,arr:Array):void {
        if (i>0) {
          g.lineTo( prevX[i], prevY[i-1] );
        }
        g.lineTo( prevX[i], prevY[i] );
      });
      g.lineTo( prevX[prevX.length-1], middle );
      g.endFill();
    }
  }
}

class Slot {

  public var data:Array = [];
  private var last:Number = -1;
  private var scaleTime:Number = 0;

  public function Slot( scaleTime:Number ) {
    this.scaleTime = scaleTime;
  }

  public function conflict( trade:Object ):Boolean {
    return last == 0 || trade.date <= last+scaleTime;
  }
  public function add( trade:Object ):void {
    data.push( trade );
    last = trade.fix_date;
    //log("last:" + String(last) )
  }
}

