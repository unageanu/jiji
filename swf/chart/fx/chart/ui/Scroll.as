package fx.chart.ui {

  import flash.display.*;
  import flash.text.*;
  import flash.external.*;
  import flash.events.*;
  import mx.core.*;
  import mx.controls.*;
  import mx.collections.ArrayCollection;
  import mx.managers.CursorManager;
  import mx.events.*;
  import flash.geom.*;

  import fx.util.*;
  import fx.chart.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.Controller;

  /**
   * スクロール
   */
  public class Scroll extends AbstractChartUI {

    private var scrollSprite:Sprite;
    private var scroll:ScrollBar;

    private var left:TextField;
    private var right:TextField;

    private var info:RangeInfoWindow;

    /**
     * ステージドラッグの開始位置
     */
    private var stageDrag:Boolean;
    private var startPosition:Point;
    private var scrollMax:int; // スクロール可能な最大ステップ数
    private var scrollMin:int; // スクロール可能な最小ステップ数

    /**
     * ステージのドラッグで移動するレイヤー
     */
    private var moveLayers:Array;

    public function Scroll(model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      info = new RangeInfoWindow(model,controller,rc);

      scrollSprite = new Sprite();
      scrollSprite.x = rc.stage.ctrl.left;
      scrollSprite.y = rc.stage.ctrl.top;
      rc.layers.ctrl.addChild(scrollSprite);

      // 期間ラベル
      left = new TextField();
      left.selectable = false;
      left.text = "";
      left.width = 150;
      left.defaultTextFormat = Constants.TEXT_FORMAT_SCROLL_LEFT;
      left.y = rc.stage.ctrl.top+10;
      left.x = rc.stage.ctrl.left;
      rc.layers.ctrl.addChild(left);

      right = new TextField();
      right.selectable = false;
      right.text = "";
      right.width = 150;
      right.defaultTextFormat = Constants.TEXT_FORMAT_SCROLL_RIGHT;
      right.y = rc.stage.ctrl.top+10;
      right.x = rc.stage.ctrl.right -70 - 200 - 20 - 150;
      rc.layers.ctrl.addChild(right);

      // ステージのドラッグでのスクロールサポート
      moveLayers = [ rc.layers.axisY, rc.layers.lowAxisY, rc.layers.main ];
      var dragSpace:Sprite = new Sprite();
      dragSpace.alpha = 0.01;
      dragSpace.graphics.beginFill(Constants.BACKGROUND_COLOR);
      dragSpace.graphics.drawRect( rc.stage.candle.x, rc.stage.candle.y,
          rc.stage.candle.width, rc.stage.xAxis.top - rc.stage.candle.top );
      dragSpace.graphics.endFill();
      rc.layers.ctrl.addChild(dragSpace);

      dragSpace.addEventListener(MouseEvent.MOUSE_DOWN, function(ev:MouseEvent):void {
//        log( "start-drag" );
//        log( "start: x=" + ev.stageX + ", y=" + ev.stageY );
        if ( model.range == null ) return; // 範囲が未ロードの場合はドラッグ不可。
        startPosition = new Point(ev.stageX, ev.stageY);

        // スクロール可能範囲を割り出し
        scrollMax = (model.startDate.getTime() /1000 - model.range.first) / model.scaleTime; // スクロール可能最小値から、現在の左端までのステップ
        scrollMin = ( model.range.last - model.endDate.getTime() /1000) / model.scaleTime * -1;

        CursorManager.setCursor( Constants.CURSOR_HAND, 2, -10, -10 );
        rc.canvas.stage.addEventListener(MouseEvent.MOUSE_MOVE, move);
        onScrollStart({});
      });
      rc.canvas.stage.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
        endDrag(event);
      });
    }
    private function endDrag(ev:MouseEvent):void {
      if (startPosition!=null) {
        CursorManager.removeAllCursors();
        rc.canvas.stage.removeEventListener(MouseEvent.MOUSE_MOVE, move);
        var step:Number = int((ev.stageX - startPosition.x) / 6);
        var positionLeft:Number = 0;

        // 範囲チェック
        if ( scrollMax <= scrollMin  ) {
          // 移動後の範囲が、表示可能範囲外
          // スクロール不可
          positionLeft = scroll.positionLeft;
        } else if (  scrollMax <= step ) {
          step = scrollMax;
          positionLeft = 0;
        }  else if ( scrollMin >= step ) {
          step = scrollMin;
          positionLeft = scroll.contentsWidth - scroll.viewWidth;
        } else {
          positionLeft = model.startDate.getTime() / 1000 - model.scaleTime * step - model.range.first;
        }

        var d:Date = new Date();
        d.setTime( model.startDate.getTime() - model.scaleTime * 1000 * step );
        scroll.scrollTo( positionLeft ); //d.getTime()/1000 - model.range.first); // スクロールバーを追従

        onScrollEnd({positionLeft: d.getTime()/1000 - model.range.first });
        startPosition = null;
      }
    }
    private function move(ev:MouseEvent):void {
      if (startPosition==null) {return;}
      var step:Number = int((ev.stageX - startPosition.x) / 6);
      var positionLeft:Number = 0;

      // 範囲チェック
      if ( scrollMax <= scrollMin  ) {
        // 移動後の範囲が、表示可能範囲外
        // スクロール不可
//        step = 0;
//        positionLeft = scroll.positionLeft;
        return;
      } else if (  scrollMax <= step ) {
        step = scrollMax;
        positionLeft = 0;
      }  else if ( scrollMin >= step ) {
        step = scrollMin;
        positionLeft = scroll.contentsWidth - scroll.viewWidth;
      } else {
        positionLeft = model.startDate.getTime() / 1000 - model.scaleTime * step - model.range.first;
      }

      // レイヤーとスクロールバーを移動
      scroll.scrollTo(positionLeft);
      onScroll({positionLeft: positionLeft });

//      log("xx:" + x);
/*
      moveLayers.forEach( function( l:*,i:Number,arr:Array ):void {
        for( var j:int=0,n:int=l.numChildren;j<n;j++ ) {
          l.getChildAt(j).x = x;
        }
      } );
*/
    }

    public function update():void {
      Util.clear(scrollSprite);
      scroll = new ScrollBar( scrollSprite,
          model.startDate.getTime()/1000 - model.range.first,
          model.range.last-model.range.first,
          model.scaleTime*Model.COUNT,
          rc.stage.ctrl.width -70 -200-20 );

      scroll.addEventListener( ScrollBar.SCROLL_START,
          onScrollStart, this);
      scroll.addEventListener( ScrollBar.SCROLL_END,
          onScrollEnd, this);
      scroll.addEventListener( ScrollBar.SCROLL,
          onScroll, this);

      left.text  = Util.formatDate(
          Util.createDate( model.range.first ), "YYYY/MM/DD");
      right.text = Util.formatDate(
          Util.createDate( model.range.last  ), "YYYY/MM/DD");

    }

    public function onScaleChanged( ev:Event ):void {
      update();
    }
    public function onRangeChanged( ev:Event ):void {
      update();
    }

    public function onScrollStart( ev:* ):void {

      var start:Number = model.startDate.getTime()/1000;

      // 範囲情報ウインドウを更新
      info.update(
          start,
          start + model.scaleTime*Model.COUNT,
          scroll.slider ? scroll.slider.x : 0 );

      // 情報系ウインドウの描画を不可視
      // 範囲情報ウインドウを描画
      rc.layers.setWindowVisible({"range":true});
    }
    public function onScrollEnd( ev:* ):void {
      // 日時を更新
      ctrl.changeDate( Util.createDate(
          model.range.first + ev.positionLeft + model.scaleTime*Model.COUNT/2) );

      // 情報系ウインドウの描画を元に戻す
      rc.layers.setWindowVisible({"info":true});
    }
    public function onScroll( ev:* ):void {
      // 範囲情報ウインドウを更新
      info.update(
          model.range.first + ev.positionLeft,
          model.range.first + ev.positionLeft + model.scaleTime*Model.COUNT,
          ev.x );

      // レイヤーを移動
//      log("ev.positionLeft:" + ev.positionLeft);
//      log("model.startDate.getTime:" + model.startDate.getTime() / 1000);
//      log("model.scaleTime:" + model.scaleTime);
      var x:int = int(( model.startDate.getTime() / 1000 - model.range.first - ev.positionLeft) / model.scaleTime ) * 6 ;
//      log("x:" + x);
//      (model.startDate.getTime() /1000 - model.range.first) / model.scaleTime;
      moveLayers.forEach( function( l:*,i:Number,arr:Array ):void {
        for( var j:int=0,n:int=l.numChildren;j<n;j++ ) {
          l.getChildAt(j).x = x;
        }
      } );
    }
  }
}