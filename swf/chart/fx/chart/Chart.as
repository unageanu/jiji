package fx.chart {

  import flash.display.*;
  import flash.text.*;
  import flash.external.*;
  import flash.net.*;
  import flash.events.Event;
  import mx.core.*;
  import mx.controls.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;
  import fx.chart.ui.candle.*;
  import fx.chart.ui.graph.*;
  import fx.chart.ui.*;
  import fx.util.*;

  /**
   * チャート
   */
  public class Chart {

    private var candleChart:CandleChart;
    private var pointer:Pointer;
    private var scaleSelector:ScaleSelector;
    private var tradeResult:TradeResult;
    private var scroll:Scroll;
    private var graphManager:GraphManager;

    private var model:Model;
    private var ctrl:Controller;
    private var rc:RenderingContext;
    private var autoUpdate:AutoUpdate;
    private var check:CheckBox;
  
    public function Chart(canvas:UIComponent){
    
      model = new Model();
      ctrl = new Controller(model);
      rc = new RenderingContext( canvas );

      autoUpdate = new AutoUpdate( model, ctrl );
      check = new CheckBox();
      check.x = 490;
      check.y = 10;
      check.label = "自動更新";
      rc.canvas.addChild( check );
      check.addEventListener( flash.events.Event.CHANGE, function():void {
          if ( check.selected ) {
              autoUpdate.start();
          } else {
              autoUpdate.stop();
          }
          var so:SharedObject = SharedObject.getLocal("chartInfo");
          so.data.autoupdate =  check.selected;
          so.flush();
      });
      ctrl.addEventListener( fx.chart.ctrl.Event.SCALE_CHANGED,
              autoUpdate.onScaleChanged, autoUpdate);
      var so:SharedObject = SharedObject.getLocal("chartInfo");
      check.selected = so.data.autoupdate;

      try {
        var loading:Loading = new Loading( model, ctrl, rc );
        ctrl.stubFactory.listenerSupport.addEventListener( fx.chart.ctrl.Event.REQUEST_COUNT_CHANGED,
              loading.onRequestCountChanged, loading  );
      
        tradeResult = new TradeResult( model, ctrl, rc );
        ctrl.addEventListener( fx.chart.ctrl.Event.TRADE_DATA_CHANGED,
            tradeResult.onTradeDataChanged, tradeResult);
        ctrl.addEventListener( fx.chart.ctrl.Event.PROFIT_DATA_CHANGED,
            tradeResult.onProfitDataChanged, tradeResult);
        
        candleChart = new CandleChart( model, ctrl, rc );
        ctrl.addEventListener( fx.chart.ctrl.Event.CANDLE_DATA_CHANGED,
            candleChart.onCandleDataChanged, candleChart);

        pointer = new Pointer( model, ctrl, rc );

        scroll = new Scroll( model, ctrl, rc );
        ctrl.addEventListener( fx.chart.ctrl.Event.RANGE_CHANGED,
            scroll.onRangeChanged, scroll);
        ctrl.addEventListener( fx.chart.ctrl.Event.SCALE_CHANGED,
            scroll.onScaleChanged, scroll);

        graphManager = new GraphManager( model, ctrl, rc );
        ctrl.addEventListener( fx.chart.ctrl.Event.CANDLE_DATA_CHANGED,
            graphManager.onCandleDataChanged, graphManager);
        ctrl.addEventListener( fx.chart.ctrl.Event.OUTPUT_LIST_CHANGED,
            graphManager.onGraphListChanged, graphManager);
        
        // 利用可能な通貨ペアの一覧を取得
        ctrl.requestPairs( function(data:Array):void {
            scaleSelector = new ScaleSelector( model, ctrl, rc, data );
            registExternalInterface();
            ExternalInterface.call( "onChartLoaded" );
        });
        
      } catch ( ex:Error ) {
        //log(ex.message + ":" + ex.getStackTrace());
      }
    }
    /**
     * 外部インターフェイスを登録
     */
    private function registExternalInterface():void {
        ExternalInterface.addCallback("initializeChart", this.initializeChart );
        ExternalInterface.addCallback("setDate", function( date:Number ):void {
            var d:Date = Util.createDate(date);
            var f:Function = function():void {
                pointer.setPosition( 
                         model.positionManager.fromDate( Math.floor( date / model.scaleTime) * model.scaleTime ) + rc.stage.candle.left,
                         rc.stage.candle.bottom - (rc.stage.candle.height/4));
                ctrl.removeEventListener(  fx.chart.ctrl.Event.CANDLE_DATA_CHANGED, arguments.callee );
             }
            ctrl.addEventListener( fx.chart.ctrl.Event.CANDLE_DATA_CHANGED, f);
            ctrl.changeDate( d );
            scroll.update();
        } );
        ExternalInterface.addCallback("setGraphVisible", this.setGraphVisible );
        ExternalInterface.addCallback("setGraphColors", this.setGraphColors );
        ExternalInterface.addCallback("removeGraph", this.removeGraph );
    }
    /**
     * グラフを初期化する
     */
    private function initializeChart( processId:String, pair:String, scale:String, date:Number ):void {
        if ( processId == "rmt" ) {
            this.check.enabled = true;
        } else {
            this.check.enabled = false;
        }
        var so:SharedObject = SharedObject.getLocal("chartInfo");
        pair = pair || so.data.pair || "EURJPY"; 
        scale = scale || so.data.scale || "10m",
        this.scaleSelector.init( pair, scale );
        this.ctrl.init( processId, pair, scale, 
                date ? Util.createDate(date) : null );
        
        if ( check.selected && check.enabled ) {
            this.autoUpdate.start();
        } else {
            this.autoUpdate.stop();
        }
        
        // 設定を記録
        if ( pair ) {  so.data.pair = pair; }
        if ( scale ) {  so.data.scale = scale; }
        so.flush();
    }
    /**
     * グラフの表示/非表示を設定
     */
    private function setGraphVisible( name:Array, visible:Boolean  ):void {
        if ( visible ) {
            this.graphManager.on( name );
        } else {
            this.graphManager.off( name );
        }
    }
    /**
     * グラフの色を設定
     */
    private function setGraphColors( name:Array, colors:Array  ):void {
        this.graphManager.setGraphColors( name, colors );
    }
    /**
     * グラフの表示/非表示を設定
     */
    private function removeGraph( agentId:String  ):void {
        this.graphManager.removeGraph( agentId );
    }
  }
}