
JSONBrokerClientFactory = {

    /**同期/非同期切り替え*/
    async : true,

    /**
     * JSONBrokerのクライアントスタブを生成する。
     * @param {String} url JSONBrokerのURL
     * @param {Function} successCallback 成功時のコールバック先
     * @param {Function} errorCallBack エラー時のコールバック先
     */
    create: function( url, successCallback, errorCallBack ) {
        JSONBrokerClientFactory._call( url, "public_methods", [], function( list ) {
            var stub = JSONBrokerClientFactory.createFromList( url, list );
            if ( successCallback ) { successCallback( stub );}
        }, errorCallBack );
    },
    /**
     * JSONBrokerのクライアントスタブを生成する。
     * @param {String} url JSONBrokerのURL
     * @param {Array} list API名の配列
     */
    createFromList: function( url, list ) {
        var stub = {};
        for ( var i=0; i<list.length; i++ ) {
            stub[list[i]] = JSONBrokerClientFactory._createFunction( url, list[i] );
        }
        return stub
    },
    _createFunction: function( url, method ) {
      return function( ) {
          var errorCallBack   = Array.prototype.pop.apply( arguments, [] );
          var successCallback = Array.prototype.pop.apply( arguments, [] );
          var args = [];
          for ( var i=0; i<arguments.length; i++ ) {
              args.push( arguments[i] );
          }
          JSONBrokerClientFactory._call( url, method,
              args, successCallback, errorCallBack );
      };
    },
    _call: function( url, method, args, successCallback, errorCallBack ) {
        var sendData = encodeURIComponent(
          '{ "method":"' + method + '", "params":' + YAHOO.lang.JSON.stringify(args) + '}');
        return new Ajax.Request(url, {
          method: "POST",
          postBody : sendData,
          evalJSON: false,
          asynchronous : JSONBrokerClientFactory.async,
          onSuccess : function( response ) {
            try {
              var data = YAHOO.lang.JSON.parse(response.responseText);
              if ( !data[0] || data[0]["error"] ) {
                  if ( errorCallBack ) errorCallBack( data[0]["error"], data[0]["detail"] );
              } else {
                  if ( successCallback ) successCallback(data[0]["result"]);
              }
            } catch ( ex ) {
               if ( errorCallBack ) errorCallBack( ex.message || ex.description || String(ex), {} );
            }
          },
          onFailure : errorCallBack,
          onException : errorCallBack
        });
    }
}
