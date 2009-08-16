package fx.chart.model {
  
  import fx.chart.model.*;
  import fx.util.*;
  
  /**
   * データ
   */
  public class TimedData {
    
    private var datas:Array;
    private var dateMap:Object;
    
    /**
     * コンストラクタ
     */
    public function TimedData(datas:Array, scaleTime:int, timeData:*):void {
      this.datas = datas;
      dateMap = {};
      datas.forEach( function( item:*, index:int, arr:Array ):void {
        var time:Number = int(item[timeData]/scaleTime)*scaleTime;
        dateMap[time] = item;
      } );
    }
    
    /**
     * 日時に対応する取引データを得る。見つからない場合null
     */
    public function getDataByDate( time:Number ):Array {
      return dateMap[time];
    }
    
    /**
     * データを配列で取得する
     */
    public function getDatas( ):Array {
      return datas;
    }
  }
}