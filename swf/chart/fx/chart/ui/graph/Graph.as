package fx.chart.ui.graph {

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
   * グラフ
   */
  public class Graph extends AbstractDrawChartUI {

    public function Graph( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );
    }

    public function draw( data:Object, colors:Array ):void {
      main.x = 0;
      Util.clear( main );
      Util.clear( axis );
      Util.clear( lowAxis );

      // データ数分のスプライトを作成
      if ( !data["datas"] || data["datas"].length <= 0 ) { return; }
      var sprites:Array = [];
      for ( var i:int=0; i< data.datas[0].length; i++ ) {
        var s:Sprite = new Sprite();
        main.addChild( s );
        sprites.push( s );
      }
      if ( data["options"]["graph_type"] == "rate" ) {
        drawWithRate( data, colors, sprites );
      } else if ( data["options"]["graph_type"] == "zero_base" ) {
        drawZeroBase( data, colors, sprites );
      } else {
        drawBasic( data, colors, sprites );
      }
    }

    /**
     * レートにあわせてグラフを書く
     */
    private function drawWithRate( data:Object, colors:Array, sprites:Array ):void {

      var pm:PositionManager = model.positionManager;
      var height:int = rc.stage.candle.height;
      var f:Function = function(value:*):int {
        return  rc.stage.candle.bottom - pm.fromRate( value, height ); 
      }
      // グラフ
      drawLineGraph( data, f, colors, sprites  );
    }

    /**
     * 0を中心とするグラフを書く
     */
    private function drawZeroBase( data:Object, colors:Array, sprites:Array ):void {

      var pm:PositionManager = model.positionManager;
      var rect:Rectangle = rc.stage.graph;
      var middle:int = rect.top + rect.height/2;
        
      var range:Array = range( data );
      var m:Number = Math.max( Math.abs(range[0]), Math.abs(range[1]) );
      var valueParPixel:Number = m*2 / rect.height;
      
      var f:Function = function(value:*):int {
        return middle - int(value / valueParPixel); 
      }
    
      // 背景線を引く
      drawAxis( data, f );
      
      // 0
      lowAxis.graphics.lineStyle( 0, Constants.COLOR_CANDLE, 1, true,
        LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      var y:int = middle;
      lowAxis.graphics.moveTo( rect.left,  y);
      lowAxis.graphics.lineTo( rect.right,  y);
      createText( "0", axis, Constants.TEXT_FORMAT_SCALE_Y,  0, middle-8, rect.left-2 );
      
      // グラフ
      drawLineGraph( data, f , colors, sprites );
    }

    /**
     * 最大値と最小値をマッピングするグラフを書く
     */
    private function drawBasic( data:Object, colors:Array, sprites:Array ):void {
      var pm:PositionManager = model.positionManager;
      var rect:Rectangle = rc.stage.graph;
 
      var range:Array = range( data );
      var diff:Number = range[1] - range[0];
      var valueParPixel:Number = diff / rect.height;
      
      var f:Function = function(value:*):int {
        return rc.stage.graph.bottom - int((value-range[0]) / valueParPixel); 
      }
      
      // 背景線を引く
      drawAxis( data,  f );
        
      // グラフ
      drawLineGraph( data, f , colors, sprites );
    }
    /**
     * 描画用のスプライトを造る。
     */
    private function createSprites( colors:Array,  sprites:Array ):Array {
      var gs:Array = [];
      for ( var i:int =0; i < sprites.length; i++ ) {
        var g: Graphics = sprites[i].graphics;
        g.lineStyle( 0, i < colors.length ? colors[i] : 0x557777, 0.8, false,
          LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
        gs.push( g );
      }
      return gs;
    }
    
    /**
     * 最大値、最小値を取得する
     */
    private function range( data:Object ):Array {

      var max:Number = Number.MIN_VALUE;
      var min:Number = Number.MAX_VALUE;

      // 線
      if ( data["options"]["lines"] ) {
        data["options"]["lines"].forEach( function( item:*,i:int,arr:Array ):void{
          max = Math.max( max, item );
          min = Math.min( min, item );
        } );
      }

      // データ
      data.datas.forEach( function( item:*, i:int, arr:Array ):void {
        for ( var j:int =0; j < item.length-3; j++ ) {
          max = Math.max( max, item[j] );
          min = Math.min( min, item[j] );
        }
      } );

      // マージンを上下に確保
      if ( max == min ) {
        var d:Number = max * 0.01;
        min = max - d;
        max = max + d;
      } else {
        max += (max - min ) * 0.1;
        min -= (max - min ) * 0.1;
      }
      return [min,max];
    }

    /**
     * 背景線を描画する。
     */
    private function drawAxis( data:Object, f:Function ):void {
      var rect:Rectangle = rc.stage.graph;
      lowAxis.graphics.lineStyle( 0, Constants.COLOR_AXIS_RIGHT, 1, true,
        LineScaleMode.NONE, CapsStyle.NONE, JointStyle.BEVEL );
      if ( data["options"]["lines"] ) {
        data["options"]["lines"].forEach( function( item:*,i:int,arr:Array ):void{
            var y:int = f(item); 
            lowAxis.graphics.moveTo( rect.left,  y);
            lowAxis.graphics.lineTo( rect.right,  y);
            createText( String(item), axis,  Constants.TEXT_FORMAT_SCALE_Y,  0, y-8, rect.left-2 );
        } );
      }
    }
    
    /**
     * 線グラフを描画する。
     */
    private function drawLineGraph( data:Object, f:Function, colors:Array, sprites:Array ):void {
      if ( data.datas.length <= 0 ) { return; }
      var pm:PositionManager = model.positionManager;
      var gs:Array =createSprites( colors, sprites );
      data.datas.forEach( function( item:*, i:int, arr:Array ):void {
        var x:int =  pm.fromDate( item[item.length-1] ) + rc.stage.candle.left;
        for ( var j:int =0; j < item.length-3; j++ ) {
          var y:int = f( item[j] );
          if ( i == 0 ) {
            gs[j].moveTo( x, y )
          } else {
            gs[j].lineTo( x, y )
          }
        }
      });
    }
  }
}