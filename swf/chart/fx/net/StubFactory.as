package fx.net {
  
  import fx.util.*;
    
  /**
   * スタブファクトリ
   */
  public class StubFactory  {
    
    /**
     * エンドポイント
     */
    private var endPoint:String = "./json";

    /**
     * リスナ
     */
    public var listenerSupport:ListenerSupport = new ListenerSupport();
    
    /**
     * コンストラクタ
     */ 
    public function StubFactory( endPoint:String ) {
      this.endPoint = endPoint;
    }
    
    /**
     * スタブを生成する。
     */
    public function create( name:String ):* {
      return new Stub( endPoint + "/" + name, this );
    }
    
    
  }
}

import flash.errors.*;
import flash.events.*;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.utils.Proxy;
import flash.utils.flash_proxy;
import com.adobe.serialization.json.JSON;
import fx.net.*
import fx.chart.ctrl.Event;

// スタブ
dynamic class Stub extends Proxy {
  
  /**現在進行中のリクエスト数*/
  private static var requestCount:int = 0;
  
  private var endPoint:String;
  private var sf:StubFactory;
  
  function Stub( endPoint:String, sf:StubFactory ) {
    this.endPoint = endPoint;
    this.sf = sf;
  }
  flash_proxy override function callProperty(name:*, ...rest):* {
    var fail:Function = rest.pop();
    var success:Function = rest.pop();
    
    // リクエストを生成
    var request:URLRequest = new URLRequest();
    request.url = endPoint;
    var data:String = JSON.encode({
        "method":name.toString(), "params":rest, "time":new Date().getTime()
    });
    //log(data);
    //request.method = URLRequestMethod.POST;
    var variable:URLVariables = new URLVariables();
    variable.request = data;
    request.data = variable;
    
    // ローダーを生成し、イベントハンドラを設定
    var loader:URLLoader = new URLLoader();
    loader.addEventListener(flash.events.Event.COMPLETE, function( ev:flash.events.Event):void {
       changeRequestCount(-1);
       //log(ev.target.data);
       var result:Object = JSON.decode( ev.target.data)[0];
       if ( result["error"] ) {
          fail.apply(null, [result["error"]] );
       } else {
          success.apply(null, [result["result"]] );
       }
    });
    loader.addEventListener(IOErrorEvent.IO_ERROR, function( ev:IOErrorEvent ):void {
       changeRequestCount(-1);
       fail.apply(null, [ev] );
    });
    loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function( ev:SecurityErrorEvent ):void {
       changeRequestCount(-1);
       fail.apply(null, [ev] );
    });
    
    try {
        loader.load(request);
        changeRequestCount(1);
    } catch (error:*) {
        fail.apply(null, [error] );
    }
  }
  private function changeRequestCount( diff:int  ):void {
      requestCount+= diff;
      //log( "request count : " + String(requestCount) );
      sf.listenerSupport.fire( fx.chart.ctrl.Event.REQUEST_COUNT_CHANGED, 
              {"requestCount":requestCount} );
  }
} 