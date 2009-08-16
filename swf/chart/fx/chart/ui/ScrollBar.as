package fx.chart.ui {

  import flash.display.*;
  import flash.text.*;
  import flash.external.*;
  import flash.events.*;
  import flash.geom.*;
  import mx.core.*;
  import mx.controls.*;
  import mx.collections.ArrayCollection;
  import mx.events.*;

  import fx.util.*;
  import fx.chart.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.Controller;

  /**
   * スクロール
   */
  public class ScrollBar {

    public static const SCROLL_START:String = "SCROLL_START";
    public static const SCROLL_END:String = "SCROLL_END";
    public static const SCROLL:String = "SCROLL";

    /**表示先スプライト*/
    private var sprite:Sprite;
    /**スライダー*/
    public var slider:Sprite;

    /**スクロールバーの幅(左右のボタン、ボーダー部分を含む)*/
    public var width:Number;

    /**スライダーの幅*/
    public var sliderWidth:Number;
    /**スライダーの移動範囲*/
    public var barWidth:Number;

    /**データの幅*/
    public var contentsWidth:Number;
    /**データ中の表示範囲の幅*/
    public var viewWidth:Number;
    /**スライダーの現在位置(左辺の値)*/
    public var positionLeft:Number;

    /**
     * スクロール可能かどうか。
     * コンテンツの幅　<= 表示幅の場合false
     */
    public var scrollEnable:Boolean = true;

    private var drag:Boolean = false;
    private var listeners:Object = {};

    private var localPosition:Point = null;

    /**
     * コンストラクタ
     * @param sprite 表示先スプライト
     * @param position 現在位置
     * @param contentsWidth コンテンツの幅
     * @param viewWidth 表示幅
     * @param width スクロールバーの幅
     */
    public function ScrollBar( sprite:Sprite, positionLeft:Number,
       contentsWidth:Number, viewWidth:Number, width:Number ) {

      this.sprite = sprite;
      this.width = width;
      this.barWidth = width-26-4;
      this.contentsWidth = contentsWidth;
      this.viewWidth = viewWidth;
      setPositionLeft( positionLeft );

      // スライダー
      this.sliderWidth =
        Math.floor(barWidth * (viewWidth/contentsWidth));
      if ( this.sliderWidth <= 15 ) {
        this.sliderWidth = 15;
      } else if ( this.sliderWidth >= width-30 ) {
        this.sliderWidth = 0;
        this.scrollEnable = false;
      }
      // 外枠
      createOuter();

      if ( scrollEnable ) {
        createSlider( );
      }
      // ボタン
      createButtons( );
    }

    /**
     * イベントリスナを追加する。
     */
    public function addEventListener( type:String,
      listener:Function, self:*=null, priority:int=0 ):void {
      var list:Array = listeners[type];
      if ( !list ) {
        list = [];
        listeners[type] = list;
      }
      list.push( {listener:listener, priority:priority, self:self} );
      list.sortOn( "priority", Array.NUMERIC);
    }
    /**
     * イベントをキックする
     */
    public function fire( type:String, event:Object ):void {
      var list:Array = listeners[type];
      if ( !list ) {
        return;
      }
      event["type"] = type;
      for ( var i:int=0; i<list.length; i++ ) {
        list[i].listener.apply( list[i].self, [event] );
      }
    }

    private function createOuter():void {
      var g:Graphics = sprite.graphics;

      g.lineStyle( 0, COLOR_DARK, 1, true, LineScaleMode.NONE );
      g.moveTo( 2, 0 );
      g.lineTo( width-2, 0 );
      g.moveTo( 2, 12 );
      g.lineTo( width-2, 12 );

      g.lineStyle( 0, COLOR_SHADOW, 1, true, LineScaleMode.NONE );
      g.moveTo( 2, 1 );
      g.lineTo( width-2, 1 );

      g.lineStyle( 0, COLOR_LIGHT, 1, true, LineScaleMode.NONE );
      g.moveTo( 2, 11 );
      g.lineTo( width-2, 11 );

      var imgLeft:Bitmap = new IMG_OUTER_LEFT();
      imgLeft.x = 0;
      imgLeft.y = 0;
      sprite.addChild( imgLeft );

      var imgRight:Bitmap = new IMG_OUTER_RIGHT();
      imgRight.x = width-2;
      imgRight.y = 0;
      sprite.addChild( imgRight );

      var clickArea:Sprite = new Sprite();
      sprite.addChild( clickArea );
      clickArea.graphics.beginFill( 0xFFFFFF );
      clickArea.graphics.drawRect( 2, 2, width-4, 10 );
      clickArea.graphics.endFill();
      clickArea.alpha = 0.01;

      if ( scrollEnable ) {
        clickArea.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
          // 以降のイベントの伝搬は禁止
          event.stopPropagation();
          if ( event.localX < slider.x ) {
            setPositionLeft(positionLeft-viewWidth);
            slider.x = Math.floor((barWidth-sliderWidth) * (positionLeft/(contentsWidth-viewWidth))) + 15;
            fire( SCROLL_END, {"x":slider.x,"positionLeft":positionLeft});
          } else if ( event.localX > slider.x + sliderWidth ) {
            setPositionLeft(positionLeft+viewWidth);
            slider.x = Math.floor((barWidth-sliderWidth) * (positionLeft/(contentsWidth-viewWidth))) + 15;
            fire( SCROLL_END, {"x":slider.x,"positionLeft":positionLeft});
          }
        });
        clickArea.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
            // 以降のイベントの伝搬は禁止
            event.stopPropagation();
        });
      }
    }
    private function createButtons():void {
      createButton( true, function():void {
        setPositionLeft(positionLeft-viewWidth);
        slider.x = Math.floor((barWidth-sliderWidth) * (positionLeft/(contentsWidth-viewWidth))) + 15;
        fire( SCROLL_END, {"x":slider.x,"positionLeft":positionLeft});
      });
      createButton( false, function():void {
        setPositionLeft(positionLeft+viewWidth);
        slider.x = Math.floor((barWidth-sliderWidth) * (positionLeft/(contentsWidth-viewWidth))) + 15;
        fire( SCROLL_END, {"x":slider.x,"positionLeft":positionLeft});
      });
    }

    private function createButton( isLeft:Boolean, action:Function ):void {
      var bs:Sprite = new Sprite();
      sprite.addChild( bs );
      var up:Bitmap   = isLeft ? new IMG_LEFT_BUTTON() : new IMG_RIGHT_BUTTON();
      var down:Bitmap = isLeft ? new IMG_LEFT_BUTTON_DOWN() : new IMG_RIGHT_BUTTON_DOWN();
      //var over:Bitmap = isLeft ? new IMG_LEFT_BUTTON_OVER() : new IMG_RIGHT_BUTTON_OVER();
      ([down,up]).forEach( function(button:*,i:int,a:Array ):void{
        button.visible = i == 1;
        button.x = isLeft ? 2 : width -15;
        button.y = 2;
        bs.addChild( button );
      });

      if ( scrollEnable ) {
//        bs.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
//          over.visible = true;
//          down.visible = false;
//          up.visible = false;
//        });
//        bs.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
//            over.visible = false;
//            down.visible = false;
//            up.visible = true;
//          });
        bs.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
          //over.visible = false;
          down.visible = true;
          up.visible = false;
          // 以降のイベントの伝搬は禁止
          event.stopPropagation();
        });
        bs.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
          if ( down.visible ) {
            //over.visible = false;
            down.visible = false;
            up.visible = true;
            action.call();
            // 以降のイベントの伝搬は禁止
            event.stopPropagation();
          }
        });
        sprite.stage.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
          if ( down.visible ) {
            //over.visible = false;
            down.visible = false;
            up.visible = true;
            // ボタンの状態を更新するだけ。アクションはキックしない。

          }
        });
      }
    }

    private function createSlider():void {

      slider = new Sprite();
      var g:Graphics = slider.graphics;

      g.beginFill( COLOR_DARK );
      g.drawRect( 1, 1, sliderWidth-2, 8 );
      g.endFill();

      g.lineStyle( 0, COLOR_LIGHT, 1, true, LineScaleMode.NONE );
      g.moveTo( 1, 0 );
      g.lineTo( sliderWidth-1, 0 );

      g.lineStyle( 0, COLOR_SHADOW, 1, true, LineScaleMode.NONE );
      g.moveTo( 1, 8 );
      g.lineTo( sliderWidth-1, 8 );

      var imgLeft:Bitmap = new IMG_SLIDER_LEFT();
      imgLeft.x = 0;
      imgLeft.y = 0;
      slider.addChild( imgLeft );

      var imgRight:Bitmap = new IMG_SLIDER_RIGHT();
      imgRight.x = sliderWidth-1;
      imgRight.y = 0;
      slider.addChild( imgRight );

      var imgHandle:Bitmap = new IMG_HANDLE();
      imgHandle.x = Math.ceil(sliderWidth/2) - 2;
      imgHandle.y = 3;
      slider.addChild( imgHandle );

      slider.x = Math.floor((barWidth-sliderWidth) * (positionLeft/(contentsWidth-viewWidth))) + 15;
      slider.y = 2;
      sprite.addChild(slider);

      slider.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void {
        // 横方向にのみ移動可能
        slider.startDrag(false, new Rectangle(15, 2, barWidth-sliderWidth, 0) );
        drag = true;
        localPosition = new Point(event.localX, event.localY);
        sprite.stage.addEventListener(MouseEvent.MOUSE_MOVE, move);
        fire( SCROLL_START, {} );

        // 以降のイベントの伝搬は禁止
        event.stopPropagation();
      });
      slider.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
        endDrag(event);
      });
      sprite.stage.addEventListener(MouseEvent.MOUSE_UP, function(event:MouseEvent):void {
        endDrag(event);
      });
    }
    private function move(ev:MouseEvent):void {
      var positionLeft:Number = (slider.x - 15) / (barWidth-sliderWidth) * (contentsWidth-viewWidth);
      fire( SCROLL, {"x":slider.x,"positionLeft":positionLeft} );
    }
    private function endDrag(ev:MouseEvent):void {
      if (drag) {
        sprite.stage.removeEventListener(MouseEvent.MOUSE_MOVE, move);
        slider.stopDrag();
        drag = false;
        localPosition = null;
        setPositionLeft((slider.x - 15) / (barWidth-sliderWidth) * (contentsWidth-viewWidth));
        fire( SCROLL_END, {"x":slider.x,"positionLeft":positionLeft} );
      }
    }

    private function setPositionLeft( positionLeft:Number ):void {
      if ( positionLeft < 0 ) {
        this.positionLeft = 0;
      } else if ( positionLeft > contentsWidth - viewWidth ) {
        this.positionLeft = contentsWidth - viewWidth;
      } else {
        this.positionLeft = positionLeft;
      }
    }

    /**
     * スライダーを規定の位置までスクロールさせる
     * 見た目を変えるのみでイベントはスローしない。
     * @param positionLeft 左辺の座標値
     */
    public function scrollTo( positionLeft:Number ):void {
        setPositionLeft( positionLeft);
        var x:int = Math.floor((barWidth-sliderWidth) * (positionLeft/(contentsWidth-viewWidth))) 
        if ( !slider ) { return; }
        if ( x <= 0 ) {
            slider.x =15;
        } else if ( x + sliderWidth >= barWidth ) {
            slider.x = barWidth - sliderWidth + 15;
        } else {
            slider.x = x + 15;
        }
        //slider.x = x <= 0 ? 0 : x >= contentsWidth - barWidth ? :  +15;
      }

    [Embed(source="resource/scroll_outer_left.gif")]
    public static var IMG_OUTER_LEFT:Class;
    [Embed(source="resource/scroll_outer_right.gif")]
    public static var IMG_OUTER_RIGHT:Class;

    [Embed(source="resource/scroll_left_button.gif")]
    public static var IMG_LEFT_BUTTON:Class;
    [Embed(source="resource/scroll_right_button.gif")]
    public static var IMG_RIGHT_BUTTON:Class;
    [Embed(source="resource/scroll_left_button_d.gif")]
    public static var IMG_LEFT_BUTTON_DOWN:Class;
    [Embed(source="resource/scroll_right_button_d.gif")]
    public static var IMG_RIGHT_BUTTON_DOWN:Class;
    [Embed(source="resource/scroll_left_button_o.gif")]
    public static var IMG_LEFT_BUTTON_OVER:Class;
    [Embed(source="resource/scroll_right_button_o.gif")]
    public static var IMG_RIGHT_BUTTON_OVER:Class;
    [Embed(source="resource/scroll_left_button_g.gif")]
    public static var IMG_LEFT_BUTTON_GRAY:Class;
    [Embed(source="resource/scroll_right_button_g.gif")]
    public static var IMG_RIGHT_BUTTON_GRAY:Class;

    [Embed(source="resource/scroll_slider_left.gif")]
    public static var IMG_SLIDER_LEFT:Class;
    [Embed(source="resource/scroll_slider_right.gif")]
    public static var IMG_SLIDER_RIGHT:Class;

    [Embed(source="resource/scroll_handle.gif")]
    public static var IMG_HANDLE:Class;

    public static const COLOR_X_SHADOW:uint = 0x666666;
    public static const COLOR_SHADOW:uint = 0x787875;
    public static const COLOR_DARK:uint = 0xC8C8C5;
    public static const COLOR_BASE:uint = 0xE5E5E5;
    public static const COLOR_LIGHT:uint = 0xF3F3F0;
    public static const COLOR_X_LIGHT:uint = 0xFFFFFF;
  }

}