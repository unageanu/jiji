package fx.chart.ui {

  import flash.events.*;
  import flash.display.*;
  import fx.chart.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;

  /**
   * クロスポインタ
   */
  public class Pointer extends AbstractChartUI {

    private var informationWindow:InformationWindow;
    private var pointerLayerX:Sprite;
    private var pointerLayerY:Sprite;


    public function Pointer( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );

      var pointerLayer:Sprite = rc.layers.pointer;

      var stageWidth:int = rc.stage.width;
      var stageHeight:int = rc.stage.height;

      pointerLayerX = new Sprite();
      pointerLayerX.graphics.lineStyle( 0, Constants.COLOR_POINTER_LINE, 1,
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      pointerLayerX.graphics.moveTo( 0, 0 );
      pointerLayerX.graphics.lineTo( stageWidth, 0 );
      //pointerLayerX.width = 10;

      pointerLayerY = new Sprite();
      pointerLayerY.graphics.lineStyle( 0, Constants.COLOR_POINTER_LINE, 1,
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      pointerLayerY.graphics.moveTo( 0, 0 );
      pointerLayerY.graphics.lineTo( 0, stageHeight );
      //pointerLayerY.height = 10;

      pointerLayer.addChild( pointerLayerX );
      pointerLayer.addChild( pointerLayerY );

      // 情報ウインドウ
      informationWindow = new InformationWindow(model,controller,rc);

      // イベントをキャプチャ
      pointerLayer.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }
    public function setPosition( x:int, y:int ):void {
        pointerLayerY.x = x;
        pointerLayerX.y = y;
        informationWindow.setPosition(x,y);
    }
    private function onMouseMove( ev:MouseEvent ):void {
        setPosition( ev.stageX, ev.stageY );
    }
  }

}