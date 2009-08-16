package fx.util {
  
  /**
   * リスナ
   */
  public class ListenerSupport  {

    /**
     * リスナ
     */
    private var listeners:Object = {};
      
    /**
     * イベントリスナを追加する。
     */
    public function addEventListener( type:String,
      listener:Function, self:*=null, priority:int=0 ):void {
      var list:Array = listeners[type];
      if ( !list ) {
        list = [];
        listeners[type] = list;
      }
      list.push( {listener:listener, priority:priority, self:self} );
      list.sortOn( "priority", Array.NUMERIC);
    }
    
    /**
     * イベントリスナを削除する。
     */
    public function removeEventListener( type:String,
      listener:Function ):void {
      var list:Array = listeners[type];
      if ( !list ) {
        var tmp:Array = [];
        list.forEach( function(item:*,i:int,arr:Array):void { 
            if ( item.listener != listener ) tmp.add( item );
        } );
        listeners[type] = tmp;
      }
    }
    
    /**
     * イベントをキックする
     */
    public function fire( type:String, ev:* ):void {
      var list:Array = listeners[type];
      if ( !list ) {
        return;
      }
      for ( var i:int=0; i<list.length; i++ ) {
        list[i].listener.apply( list[i].self, [ev] );
      }
    }
  }
}