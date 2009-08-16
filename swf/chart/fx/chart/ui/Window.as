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
  
  /**
   * ウインドウ
   */
  public class Window extends AbstractChartUI  {
    
    internal static const LINE_COLOR:uint = 0xFFFFFF;
    internal static const FILL_COLOR:uint = 0xFFFFFF;
    internal static const FILL_COLOR_DARK:uint = 0xF2F2EE;
    internal static const LINE_COLOR_HIGH:uint = 0x939390;
    internal static const LINE_COLOR_LOW:uint = 0xa3a3a0;
    internal static const LINE_COLOR_AURA:uint = 0x76afaa;
    
    /**ウインドウを描画するスプライト*/
    public var window:Sprite;
    
    public function Window( model:Model, controller:Controller, 
        rc:RenderingContext, layer:Sprite, width:int, height:int ) {
      
      super( model,controller,rc );
      
      var stageWidth:int = rc.stage.width;
      var stageHeight:int = rc.stage.height;
      
      // 情報ウインドウ
      window = new Sprite();
      var g:Graphics = window.graphics;
      
      // 本体
      var matrix:Matrix = new Matrix();
      matrix.createGradientBox(250, 250, 0, -50, -60);
      g.beginGradientFill(
          GradientType.RADIAL,
          [FILL_COLOR, FILL_COLOR_DARK], 
          [1,0.65], 
          [0x00, 0xFF],
          matrix, SpreadMethod.PAD,
          InterpolationMethod.RGB, 0)
      g.drawRect( 0, 0, width, height );
      g.endFill();
      
      // 周りの白
      g.lineStyle( 0, LINE_COLOR, 1, 
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      g.drawRect( 0, 0, width, height );
      
      // 内線
      g.lineStyle( 2, LINE_COLOR_AURA, 0.2, 
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      g.drawRect( -2, -2, width+5, height+5 );
      
      // 左上辺
      g.lineStyle( 0, LINE_COLOR_HIGH, 1, 
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      g.moveTo( -1, height+1 );
      g.lineTo( -1, -1 );
      g.lineTo( width+1, -1 );
      
      // 右下辺
      g.lineStyle( 0, LINE_COLOR_LOW, 1, 
          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      g.moveTo( 0, height+1 );
      g.lineTo( width+1, height+1 );
      g.lineTo( width+1, 0 );
      
      
      
      // 内線
//      g.lineStyle( 0, LINE_COLOR_HIGH, 0.8, 
//          true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );

//      g.moveTo( 6, 1 );
//      g.lineTo( width-6, 1 );
//      g.lineTo( width-1, 6 );
//      g.lineTo( width-1, height-6 );
//      g.lineTo( width-6, height-1 );
//      g.lineTo( 6, height-1 );
//      g.lineTo( 1, height-6 );
//      g.lineTo( 1, 6 );
//      g.lineTo( 6, 1 );
      
      layer.addChild( window );
    }
  }
}