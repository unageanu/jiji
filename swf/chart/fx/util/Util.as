package fx.util {

  import mx.formatters.*;
  import flash.display.*;
  
  /**
   * ユーティリティ
   */
  public class Util  {
  
    public static function parseScale( scale:String ):int {
      var pattern:RegExp = /^(\d+)([smhd])$/;
      var result:Object = pattern.exec(scale);
      switch( result[2] ) {
        case "s": return int(result[1])
        case "m": return int(result[1])*60
        case "h": return int(result[1])*60*60
        case "d": return int(result[1])*60*60*24
      }
      throw "illegal scale.scale=" + scale;
    }
    
    public static function formatDate( 
        date:Date, formatString:String="YYYY/MM/DD JJ:NN:SS" ):String {
      var formatter:DateFormatter = new DateFormatter();
      formatter.formatString = formatString;
      return formatter.format( date );
    }
    
    /**
     * Dateを作る
     */
    public static function createDate( src:Number ):Date {
      var d:Date = new Date();
      d.setTime( src*1000 );
      return d;
    }
    
    /**
     * レイヤーのグラフィック、テキストをすべて削除する。
     */
    public static function clear( layer:Sprite ):void {
      layer.graphics.clear();
      while( layer.numChildren > 0 ) {
        layer.removeChildAt(0);
      }
    }
    
//    /**
//     * レイヤー配下のスプライトをすべて取得する。
//     */
//    public static function children( layer:Sprite ):Array {
//      var list = [];
//      layer.children
//      for(  ) {
//        layer.removeChildAt(0);
//      }
//    }
    
  }
}