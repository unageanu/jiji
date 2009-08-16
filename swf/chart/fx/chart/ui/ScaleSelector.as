package fx.chart.ui {
  
  import flash.display.*;
  import flash.text.*;
  import flash.external.*;
  import flash.events.*;
  import mx.core.*;
  import mx.controls.*;
  import mx.collections.ArrayCollection;
  import mx.events.*;
  import fx.chart.model.Model;
  import fx.chart.ctrl.Controller;
  
  /**
   * 通貨ペアと表示倍率を設定するUI
   */
  public class ScaleSelector extends AbstractChartUI {
    
    private var pairSelector:ComboBox;
    private var scaleSelector:ComboBox;
  
    public function ScaleSelector(model:Model, 
        controller:Controller, rc:RenderingContext, pairs:Array ) {
      super( model,controller,rc );
      
      pairSelector = new ComboBox();
      var tmp:Array = [];
      for (var i:int=0;i<pairs.length;i++) {
          tmp[i] =  {label:pairs[i], data:pairs[i]};
      }
      pairSelector.dataProvider = new ArrayCollection(tmp);
      pairSelector.width = 100;
      pairSelector.x = rc.stage.ctrl.right - 200 - 5;
      pairSelector.y = rc.stage.ctrl.top;
      rc.canvas.addChild( pairSelector );
      
      scaleSelector = new ComboBox();
      scaleSelector.dataProvider = new ArrayCollection([ 
        {label:"1分足", data:"1m"}, 
        {label:"5分足", data:"5m"}, 
        {label:"10分足", data:"10m"}, 
        {label:"30分足", data:"30m"}, 
        {label:"1時間足", data:"1h"}, 
        {label:"6時間足", data:"6h"}, 
        {label:"日足", data:"1d"},  
        {label:"2日足", data:"2d"},
        {label:"5日足", data:"5d"}
      ]);
      scaleSelector.selectedIndex = 2; 
      scaleSelector.width = 100;
      scaleSelector.x = rc.stage.ctrl.right - 100;
      scaleSelector.y = rc.stage.ctrl.top;
      rc.canvas.addChild( scaleSelector );
      
      // イベントをキャプチャ
      pairSelector.addEventListener(ListEvent.CHANGE, onPairChanged);
      scaleSelector.addEventListener(ListEvent.CHANGE, onScaleChanged);
      
    }
    /**
     * コンボボックスの値を更新する(初期化時用/イベントの通知はされない)
     */
    public function init( pair:String, scale:String ):void {
        setValue( scaleSelector, scale);
        setValue( pairSelector, pair);
    }
    private function setValue( c:ComboBox, value:String ):void {
        for ( var i:int=0;i<c.dataProvider.length; i++ ) {
            if ( c.dataProvider.getItemAt(i).data == value ) {
                c.selectedIndex = i;
                break;
            }
        }
    }
    
    private function onPairChanged( ev:ListEvent ):void {
      ctrl.changePair(ev.currentTarget.selectedItem.data);
    }
    private function onScaleChanged( ev:Event ):void {
      ctrl.changeScale(ev.currentTarget.selectedItem.data);
    }
    
  }
}