if(typeof container=="undefined"){
  container={}
}
if(typeof container.utils=="undefined"){
  container.utils={}
}


/**
 * コンポーネントのフィールドの変更を捕捉するリスナを設定する。
 */
container.utils.ListenerBinder = function() {
    this.recipe = {}; // @Inject
}
container.utils.ListenerBinder.prototype = {
  meta: {
    "@Container": {
      "@Scope": container.Scope.EagerSingleton,
      "@Initialize": function( binder, container ) { binder.bind( container ); }
    }
  },

  /**
   * コンポーネント定義を元にモデルのリスナを設定する。
   * @param {Object} c コンテナ
   */
  bind: function( c ) {
    for ( var i in this.recipe ) {
      if ( typeof i == "function" ) { continue; }
      var result = new RegExp( "(.*)#(.*)$").exec( i );
      if ( result && result.length >= 3 ) {
        var fn = this.recipe[i];
        var component = c.get( result[1] );
        var listeners = c.gets( container.types.has( fn ) );
        if ( component && listeners && result[2]) {
            this.addListeners( component, result[2], listeners, fn );
        }
      }
    }
  },

  /**
   * 更新リスナを追加する。
   * @param {Object} target リスナを追加するモデル
   * @param {String} key イベントキー
   * @param {Function} listener リスナ関数の配列
   * @param {String} functionName 関数名
   */
  addListeners: function ( target, key, listeners, functionName ) {
    if ( !target.__listeners ) {

      // ターゲットを拡張する。
      target.__listeners = {}; // リスナの記録先を確保。
      var org = target.set;

      // setを上書き。変更を受けてリスナをキックする関数にする。
      target.set = function( key, value, opt ) {
        opt = opt ? opt : {};
        opt.value = value;
        var result = null;
        if ( org ) {
            result = org.apply( target, [key, value, opt] );
        } else {
            this[key] = value;
        }
        if ( this.__listeners[key] ) {
            var fn = this.__listeners[key]["function"];
            for (var i=0; i < this.__listeners[key]["lis"].length; i++ ) {
                this.__listeners[key]["lis"][i][fn]( opt );
            }
        }
        return result;
      }
    }
    // リスナをターゲットの属性として追加。
    target.__listeners[key] = {"lis":listeners, "function": functionName};
  }
}
