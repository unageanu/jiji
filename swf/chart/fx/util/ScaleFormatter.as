package fx.util {
  
  import flash.display.*;
  import flash.text.*;
  import flash.external.*;
  import mx.formatters.*;
  
  /**
   * スケール整形機
   */
  public class ScaleFormatter  {
    
    private var scaleStr:String;
    private var period:Function;
    private var next:Date;
    
    public function ScaleFormatter( scaleStr:String ):void{
      this.scaleStr = scaleStr;
      
      // スケールから間隔を取得しておく。
      switch ( scaleStr ) {
        case "1m":
          period = function(d:Date):Date {
            d.setTime( d.getTime() + 1000*60*60 );
            return d;
          };
          break;
        case "5m":
          period = function(d:Date):Date {
            d.setTime( d.getTime() + 1000*60*60*3 );
            return d;
          };
          break;
        case "10m":
          period = function(d:Date):Date {
            d.setTime( d.getTime() + 1000*60*60*6 );
            return d;
          };
          break;
        case "30m":
          period = function(d:Date):Date {
            d.setTime( d.getTime() + 1000*60*60*12 );
            return d;
          };
          break;
        case "1h":
          period = function(d:Date):Date {
            d.setTime( d.getTime() +1000*60*60*24 );
            return d;
          };
          break;
        case "6h":
          period = function(d:Date):Date {
            d.setTime( d.getTime() + 1000*60*60*24*4 );
            return d;
          };
          break;
        case "12h":
          period = function(d:Date):Date {
            d.setTime( d.getTime() + 1000*60*60*24*10 );
            return d;
          };
          break;
        case "1d":
        case "2d":
          period = function(d:Date):Date {
            if ( d.getMonth() >= 11 ) {
              d.setFullYear( d.getFullYear()+1, 0, 1 );
            } else {
              d.setMonth( d.getMonth()+1 );
            }
            return d;
          };
          break;
        case "5d":
          period = function(d:Date):Date {
            if ( d.getMonth() >= 10 ) {
              d.setFullYear( d.getFullYear()+1, (d.getMonth()+2)%12, 1 );
            } else {
              d.setMonth( d.getMonth()+2 );
            }
            return d;
          };
          break;
      }
    }
    public function start( start:Date ):void {
    
      // 開始データが属する最寄の表示日時を取得
      switch ( scaleStr ) {
        case "1m":
          start.setHours( start.getHours(), 0, 0, 0 );
          break;
        case "5m":
          start.setHours( start.getHours() - (start.getHours() % 3), 0, 0, 0 );
          break;
        case "10m":
          start.setHours( start.getHours() - (start.getHours() % 6), 0, 0, 0 );
          break;
        case "30m":
          start.setHours( start.getHours() - (start.getHours() % 12), 0, 0, 0 );
          break;
        case "1h":
          start.setHours( start.getHours() - (start.getHours() % 24), 0, 0, 0 );
          break;
        case "6h":
          start.setHours( 0, 0, 0, 0 );
          start.setDate( start.getDate() - (start.getDate() % 5) );
          break;
        case "12h":
          start.setHours( 0, 0, 0, 0 );
          start.setDate( start.getDate() - (start.getDate() % 10) );
          break;
        case "1d":
        case "2d":
        case "5d":
          start.setHours( 0, 0, 0, 0 );
          start.setDate( 1 );
          break;
      }
      next = period.call( null, start );
    }
    public function nextDate( ):Date {
      var n:Date = new Date();
      n.setTime( next.getTime() );
      next = period.call( null, next );
      return n;
    }
    public function format( date:Date ):String {
      var formatter:DateFormatter = new DateFormatter();
      switch ( scaleStr ) {
        case "1m":
        case "5m":
        case "10m":
          formatter.formatString = "JJ:00";
          break;
        case "30m":
          formatter.formatString = "MM/DD JJ:00";
          break;
        case "1h":
        case "6h":
        case "12h":
          formatter.formatString = "MM/DD";
          break;
        case "1d":
          formatter.formatString = "YYYY/MM/DD";
          break;
        case "2d":
        case "5d":
          formatter.formatString = "YYYY/MM";
          break;
      }
      return formatter.format( date );
    }
  }
}