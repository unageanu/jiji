package fx.chart.ctrl {

  import fx.chart.*;
  import fx.chart.model.*;
  import fx.net.*;
  import fx.util.*;
  import flash.net.*;

  /**
   * コントローラー
   */
  public class Controller {

    private var model:Model;
    private var listener:ListenerSupport = new ListenerSupport();
  
    private var rateService:*;
    private var outputService:*;
    private var tradeResultService:*;
    private var processService:*;
    
    public var stubFactory:StubFactory;
  
    /**
     * コンストラクタ
     */
    public function Controller(model:Model) {
      this.model = model;

      stubFactory = new StubFactory("./json");
      rateService = stubFactory.create("rate");
      tradeResultService = stubFactory.create("trade_result");
      outputService = stubFactory.create("output");
      processService = stubFactory.create("process");
    }

    /**
     * イベントリスナを追加する。
     */
    public function addEventListener( type:String,
      listener:Function, self:*=null, priority:int=0 ):void {
        this.listener.addEventListener( type,listener,self, priority);
    }
    
    /**
     * イベントリスナを削除する。
     */
    public function removeEventListener( type:String,
      listener:Function ):void {
        this.listener.removeEventListener( type,listener);
    }
    
    /**
     * イベントをキックする
     */
    public function fire( type:String ):void {
        var ev:Event = new Event( type, model );
        listener.fire( type, ev );
    }

    /**
     * プロセスIDを更新する
     */
    public function changeProcessId( pid:String ):void {
      if ( model.processId != pid ) {
        model.processId = pid;
        updateChartData( );
        updateEnableData( );
        updateOutputList( );
        fire( Event.PROCESS_ID_CHANGED );
      }
    }

    /**
     * 通貨ペアを更新する
     */
    public function changePair( pair:String ):void {
      if ( model.pair != pair ) {
        model.pair = pair;
        save( "pair",  pair);
        updateChartData( );
        updateEnableData( );
      }
    }

    /**
     * スケールを更新する
     */
    public function changeScale( scale:String ):void {
      if ( model.scale != scale ) {
        model.scale = scale;
        save( "scale",  scale );
        updateAll();
        fire( Event.SCALE_CHANGED );
      }
    }

    /**
     * 表示日時を更新する
     */
    public function changeDate( date:Date ):void {
      if ( model.date != date ) {
        model.date = date;
        updateChartData( );
        updateTradeData( );
        updateProfitData( );
        fire( Event.DATE_CHANGED );
      }
    }
    
    /**
     * 指定されたデータでチャートを初期化する。
     * dateがnullの場合、利用可能な日時を取得し「最新の日時が真ん中あたりに来る」ように調整する。
     * 
     */
    public function init( processId:String, pair:String, scale:String, date:Date ):void {
        
        // 調整不要なデータは先に設定。(利用可能範囲の取得で少なくともprocessIDは必要。)
        model.processId = processId;
        model.pair = pair;
        model.scale = scale;
        
        _updateEnableData( function( range:Object ):void {
            model.range = range;
            var date:Number =  model.range.last - Model.COUNT/2*model.scaleTime;
            model.date = Util.createDate(date);

            // チャートを更新
            updateChartData( );
            updateTradeData( );
            updateProfitData( );
            updateOutputList( );
            // 利用可能データ更新イベントをキックして、スクロールバーを更新。
            fire( Event.RANGE_CHANGED );
        });
    }
    
    /**
     * すべてを更新する
     */
    public function updateAll():void {
      updateChartData( );
      updateTradeData( );
      updateProfitData( );
      updateEnableData( );
      updateOutputList( );
    }

    /**
     * ローソク足チャートを更新する
     */
    public function updateChartData():void {
      rateService.list( model.pair, model.scale,
          model.startDate.getTime()/1000, model.endDate.getTime()/1000,
          function( datas:Array ):void {
            model.rateDatas = model.createTimedDatas(datas, 5);
            fire( Event.CANDLE_DATA_CHANGED );
          }, function(error:*):void {
            log(error); // TODO
          } );
    }
    /**
     * 取引データを更新する
     */
    public function updateTradeData( ):void {
      tradeResultService.list( model.processId, model.scale,
          model.startDate.getTime()/1000, model.endDate.getTime()/1000,
          function( datas:Array ):void {
            model.tradeDatas = model.createTimedDatas(datas, 10);
            fire( Event.TRADE_DATA_CHANGED );
          }, function(error:*):void {
            log(error); // TODO
          } );
    }
    /**
     * 損益データを更新する
     */
    public function updateProfitData( ):void {
      tradeResultService.list_profit_or_loss( model.processId, model.scale,
          model.startDate.getTime()/1000, model.endDate.getTime()/1000,
          function( datas:Array ):void {
            model.profitDatas = model.createTimedDatas(datas, 4);
            fire( Event.PROFIT_DATA_CHANGED );
          }, function(error:*):void {
            log(error); // TODO
          } );
    }


    /**
     * outputsデータ一覧を更新する
     */
    public function updateOutputList( ):void {
        var names:Array = [];
        outputService.list_outputs( model.processId,
            function( datas:Object ):void {
              model.graphs = datas;
              fire( Event.OUTPUT_LIST_CHANGED );
            }, function(error:*):void {
              log(error); // TODO
            } );
    }

    /**
     * 表示可能な期間を更新する
     */
    public function updateEnableData( ):void {
        _updateEnableData( function( range:Object ):void {
            model.range = range;
            fire( Event.RANGE_CHANGED );
        });
    }
    /**
     * 表示可能な期間を更新する
     */
    private function _updateEnableData( f:Function ):void {

      // rmtの場合、サーバーから取得
      if ( model.processId == "rmt" ) {
          rateService.range( model.pair,
              f, function(error:*):void {
                log(error); // TODO
              } );
      } else {
          // back_testの場合、指定されているはずの日時を使う。
          processService.get( model.processId,
              function( p:Object ):void {
                var range:Object =  { 
                  "first":p.start_date,
                  "last":p.end_date 
                };
                f.call( null,  range );
              }, function(error:*):void {
                log(error); // TODO
              } );
      }
    }
    /**
     * outputsデータを取得する
     */
    public function requestOutputDatas( names:Array, callback:Function ):void {
        outputService.list_datas( model.processId, names, model.scale,
            model.startDate.getTime()/1000, model.endDate.getTime()/1000,
            function( datas:Object ):void {
              callback.call( null, datas );
            }, function(error:*):void {
              log(error); // TODO
            } );
    }
    /**
     * 利用可能な通貨ペアの一覧を取得する
     */
    public function requestPairs( callback:Function ):void {
        rateService.pairs( 
            function( datas:Array ):void {
              model.pairs = datas;
              callback.call( null, datas );
            }, function(error:*):void {
              log(error); // TODO
            } );
    }
    /**設定を記録する*/
    public function save( name:String, value:Object ):void {
        var so:SharedObject = SharedObject.getLocal("chartInfo");
        so.data[name]  = value;
        so.flush();
    }
  }

}