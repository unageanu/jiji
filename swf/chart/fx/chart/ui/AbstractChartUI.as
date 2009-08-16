package fx.chart.ui {
  
  import flash.display.*;
  import mx.core.*;
  import fx.chart.*;
  import fx.chart.ctrl.*;
  import fx.chart.model.*;
  import fx.util.*;
  import flash.text.*;
  
  /**
   * チャートUIの抽象基底クラス
   */
  public class AbstractChartUI {
    
    /**
     * コンストラクタ
     */
    public function AbstractChartUI(model:Model, 
        controller:Controller, rc:RenderingContext) {
      this.model = model;
      this.ctrl = controller;
      this.rc = rc;
    }
    
    /**
     * モデル
     */
    protected var model:Model;
    
    /**
     * コントローラー
     */
    protected var ctrl:Controller;
  
    /**
     * 描画コンテキスト
     */
    protected var rc:RenderingContext;
    
    /**
     * テキストを作る。
     */
    protected function createText( str:String, parent:Sprite, 
      format:TextFormat, x:int, y:int, width:int=100 ):TextField {
      var text:TextField = new TextField();
      text.selectable = false;
      text.text = str;
      text.width = width;
      text.setTextFormat(format);
      text.defaultTextFormat = format;
      text.y = y;
      text.x = x;
      parent.addChild(text);
      return text;
    }
  }

}