package fx.chart.model {

  import flash.net.*;
  import fx.chart.*;
  import fx.chart.ui.*;
  import fx.chart.model.*;
  import fx.util.*;

  /**
   * モデル
   */
  public class Model {
    
    /**設定情報*/
    public var so:SharedObject = SharedObject.getLocal("chartInfo");
  
    /**スクロール可能範囲の左右のマージン*/
    public static var RANGE_MARGIN:int = 20;

    /**1画面で描画するローソク足の数*/
    public static var COUNT:int = 118;
      
    /** プロセスID */
    public var processId:String;

    /** 利用可能な通貨ペア */
    public var pairs:Array;
    /** 現在表示している通貨ペア */
    public var pair:String;
    /** 現在のスケール */
    private var _scale:String;
    /** 現在のスケール */
    public var scaleTime:int;
    /** 中心日時 */
    private var _date:Date;
    /** 表示開始日時 */
    private var _startDate:Date;
    /** 表示終了日時 */
    public var endDate:Date;
    
    /**
     * 全体の開始日時と終了日時
     *   rmtの場合、レートデータの存在期間
     *   バックテストの場合バックテストの期間。
     */
    public var _range:Object;

    /**
     * グラフ情報のマップ
     */
    public var graphs:Object = {};
  
    /**
     * 日時と座標のマネージャ
     */
    public var positionManager:PositionManager = new PositionManager();
  
  
    /**
     * 現在のスケールを取得する
     */
    public function get scale():String {
      return _scale;
    }
    /**
     * 現在のスケールを設定する
     */
    public function set scale(newData:String):void {
      _scale = newData;
      scaleTime = Util.parseScale( _scale );
      if ( range ) { // スクロール可能範囲再設定し、更新する。
          this.range = _range;
      }
      if ( date ) { // 日時を再設定し、開始/終了日時を更新する。
        this.date = _date;
      }
    }
    /**
     * 日時を取得する
     */
    public function get date():Date {
      return _date;
    }
    /**
     * 日時を設定する
     */
    public function set date(newData:Date):void {
      var tmp:Number = Math.floor(newData.getTime()/1000/scaleTime)*scaleTime;
      if ( scaleTime ){
        var start:Number = tmp-COUNT/2*scaleTime;
        var end:Number = tmp+COUNT/2*scaleTime;
        if ( _range != null && (_range.last  - _range.first) <= scaleTime*COUNT ) {
            tmp = _range.first + (_range.last - _range.first ) / 2;
        } else if ( _range != null && _range.first >= start ) { 
            tmp = _range.first + scaleTime*COUNT/2;
        } else if ( _range != null && _range.last <= end) {
            tmp = _range.last - scaleTime*COUNT/2;
        }
        
        start = tmp-COUNT/2*scaleTime;
        end = tmp+COUNT/2*scaleTime;
        this.startDate = Util.createDate(start);
        this.endDate = Util.createDate(end);
        _date = Util.createDate(tmp);
      }
      _date = Util.createDate(tmp);
    }

    /**
     * 開始日時を取得する
     */
    public function get startDate():Date {
      return _startDate;
    }
    /**
     * 開始日時を設定する
     */
    public function set startDate(newData:Date):void {
      _startDate = newData;
      if ( scaleTime ){
        positionManager.updateDate( scaleTime, _startDate );
      }
    }

    /** レートデータ */
    private var _rateDatas:TimedData;

    /**
     * レートデータを取得する
     */
    public function get rateDatas():TimedData {
      return _rateDatas;
    }
    /**
     * レートデータを設定する
     */
    public function set rateDatas(newData:TimedData):void {
      _rateDatas = newData;

      // データの最大値、最小値から描画する範囲を特定
      var max:Number = 0;
      var min:Number = Number.MAX_VALUE;
      var i:int;
      var datas:Array = _rateDatas.getDatas();
      if ( datas.length <= 0 ) { return }
      for (i=0; i < datas.length; i++) {
        max = Math.max( max, datas[i][2] );
        min = Math.min( min, datas[i][3] );
      }
      // マージンを上下に確保
      if ( max == min ) {
        var d:Number = max * 0.01;
        min = max - d;
        max = max + d;
      } else {
        max += (max - min ) * 0.1;
        min -= (max - min ) * 0.1;
      }
      positionManager.updateRate( max, min );
    }

    /** トレートデータ */
    public var tradeDatas:TimedData;

    /** 損益データ */
    private var _profitDatas:TimedData;
    /**
     * 損益データを取得する
     */
    public function get profitDatas():TimedData {
      return _profitDatas;
    }
    /**
     * 損益データを設定する
     */
    public function set profitDatas(newData:TimedData):void {
      _profitDatas = newData;

      // データの最大値、最小値から描画する範囲を特定
      var max:Number = 0;
      var min:Number = Number.MAX_VALUE;
      var i:int;
      var datas:Array = _profitDatas.getDatas();
      if ( datas.length <= 0 ) { return }
      for (i=0; i < datas.length; i++) {
        max = Math.max( max, datas[i][1], datas[i][0] );
        min = Math.min( min, datas[i][1], datas[i][0] );
      }
      // マージンを上下に確保
      if ( max == min ) {
        max = 1000;
        min = -1000;
      } else {
        max += (max - min ) * 0.1;
        min -= (max - min ) * 0.1;
      }
      positionManager.updateProfit( max, min );
    }
    
    /**
     * 表示範囲を取得する
     */
    public function get range():Object {
      return _range;
    }
    /**
     * 現在のスケールを設定する
     */
    public function set range(newRange:Object):void {
      // マージンを追加。
      _range = {
          "first": newRange.first - RANGE_MARGIN*scaleTime,
          "last":newRange.last + RANGE_MARGIN*scaleTime
      };
    }

    /** アウトプットデータ */
    private var _outputDatas:Object;

    /**
     * TimedDatasを生成する
     */
    public function createTimedDatas( datas:Array, timeKey:* ):TimedData {
      return new TimedData( datas, this.scaleTime, timeKey );
    }
  }
  
}