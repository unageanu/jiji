
// ネームスペース
namespace( "util" );

/**
 * ページ管理オブジェクト
 * - ページ(classがpage-*のdiv要素)の表示/非表示を管理する。
 * - アクティブなページのみ表示。他はすべて非表示とする。
 */
util.PageManager = function ( ) {}
util.PageManager.prototype = {
  contstructor: util.PageManager.prototype.contstructor,

  /**
   * マネージャを初期化する。
   */
  init: function( pages, defaultPage ) {
    this.pages = {};
    
    for ( var i=0; i<pages.length; i++ ) {
    	if ( pages[i].id ) {
    		this.pages[pages[i].id] = pages[i];
    	}
    }
    this.current = null;
    var list = document.getElementsByTagName("div");
    var reqexp = /page-([a-zA-Z_0-9]+)/;
    for ( var i=0; i<list.length; i++ ) {
      if (  reqexp.test( list[i].className ) ) {
        this.pages[RegExp.$1] = new util.HtmlPage( RegExp.$1, list[i] );
      }
    }
    if ( defaultPage ) {
      this.to( defaultPage );
    }
  },

  /**
   * ページを移動する。
   * @param {String} pageId 表示するページのID(class名の"page-"以降の部分)
   *                         例) "page-hoge"の場合、 "hoge"
   * @param {Object} ページに渡す任意のパラメータ 
   */
  to: function( pageId, param ) {
    if ( this.current && this.pages[this.current]
      && !this.pages[this.current].from( pageId, param ) ) {
      return false;
    }
    if ( this.pages[pageId] ) {
      this.pages[pageId].to( this.current, param );
      this.current = pageId;
    }
    return true;
  },
  /**
   * 現在のページを返す。
   */
  currentPage : function() {
	  return this.pages[this.current];
  }
}

util.Page = function(id) {
  this.id = id;
}
util.Page.prototype = {
  /**
   * このページから画面を移動する際に呼び出される。
   * 戻り値としてfalseを返すと遷移をキャンセルする。
   */
  from : function(toId) {},
  /**
   * このページに画面を移動すると呼び出される。
   */
  to : function( fromId ) {
  }
}
/**
 * HTML要素に基づくページ。
 * 要素の表示/非表示で切り替える
 */
util.HtmlPage = function(id, div) {
  this.id = id;
  this.div = div;
}
util.HtmlPage.prototype = {
  from : function() {
    div.style.display = "block";
  },
  to : function( fromId ) {
    div.style.display = "none";
  }
}
