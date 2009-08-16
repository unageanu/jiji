package fx.util {

  import flash.display.*;
  import flash.text.*;
  import flash.external.*;
  import mx.formatters.*;

  /**
   * 日時に対するx座標の位置を特定する。
   */
  public class PositionManager {

    private var scale:Number;
    private var start:Number;

    /**現在のレートの最大値*/
    public var rateMax:Number;
    /**現在のレートの最小値*/
    public var rateMin:Number;
    /***/
    public var ratePerY:Number;

    public var profitMax:Number;
    public var profitMin:Number;
    public var profitPerY:Number;

    /**
     * 期間の表示範囲を更新する
     */
    public function updateDate( scale:Number, startDate:Date ):void {
      this.scale = scale;
      this.start = Math.floor(startDate.getTime()/1000);
    }
    /**
     * レートの表示範囲を更新する
     */
    public function updateRate( max:Number, min:Number ):void {
      this.rateMax = max;
      this.rateMin = min;
      this.ratePerY = rateMax - rateMin;
    }
    /**
     * 収益の表示範囲を更新する
     */
    public function updateProfit( max:Number, min:Number ):void {
      this.profitMax = max;
      this.profitMin = min;
      var m:Number = Math.max( Math.abs(profitMax), Math.abs(profitMin) );
      this.profitPerY = m ;
    }

    /**
     * 座標に対応するレートを得る。
     */
    public function toRate( y:int, height:int ):Number {
      var hp:Number = ratePerY / height;
      return (y * hp) + rateMin;
    }

    /**
     * レートに対応する座標を得る
     */
    public function fromRate( rate:Number, height:int ):int {
      var hp:Number = ratePerY / height;
      return int(( rate - rateMin ) / hp );
    }
    /**
     * 収益に対応する座標を得る
     */
    public function fromProfit( profit:Number, height:int ):int {
      return height / 2 + profit / (profitPerY / height * 2);
    }
    /**
     * 座標に対応する収益を得る。
     */
    public function toProfit( y:int, height:int ):Number {
      return (y - height / 2) * (profitPerY / height * 2);
    }

    /**
     * 日時に対するx座標(ローソクの中心となる座標)の位置を得る。
     */
    public function fromDate( date:Number ):int {
      return 6 * (( date - start ) / scale) + 6 ;
    }

    /**
     * 座標に対応する日付を得る
     */
    public function toDate( x:int ):Number {
      return Math.ceil((x-6) / 6) * scale + start;
    }
  }
}