
/**
 * ネームスペースを作成する。
 * @param {String} path 作成するネームスペース。"."区切りで指定。
 */
function namespace( path ) {
    var strs = path.split(".");
    var c = (function () { return this; })(); // グローバルオブジェクトを取得。
    for(var i=0;i<strs.length;i++) {
      if ( typeof c[strs[i]] == "undefined" ) {
          c[strs[i]] = {};
      }
      c = c[strs[i]];
    }
}

/**
 * インターセプターを適用する。
 * @param {Object} target 適用対象のオブジェクト
 * @param {Regex} regex 適用する関数名の正規表現
 * @param {Function} interceptor 適用するインターセプター
 */
function applyInterceptor( target, regex, interceptor ) {
  for ( var f in target ) {
    if ( typeof target[f] == "function" && regex.test( f ) ) {
      (function() { // f をローカル化するため関数で。
        var x = f;
        var original = target[x];
        target[x] = function( ) {
            // インターセプターを実行する関数に置き換える。
            return interceptor( x, target, original, arguments );
        }
      })();
    }
  }
}

/**
* イベントリスナの設定
* @param element リスナを設定する要素
* @param type イベントの種類 (ex. ”click”,”keydown”等)
* @param listener イベント時に発動する関数
* @param data 追加データ(省略可)
*/
function setEventListener(element, type, listener, data){
  var f = function(ev){
      var args = ev;
      args.data = (data)?data: null;
      listener(args);
  }
  if(element.addEventListener){
    // Moz系
    element.addEventListener( type, f, false);
  } else if(element.attachEvent){
    // IE系
    element.attachEvent('on' + type, f);
  }
}

namespace( "util" );

/**
 * オブジェクトの関数をコピーする
 * @param from コピー元
 * @param to コピー先
 * @return コピー先
 */
util.merge = function ( from, to ) {
  for ( var k in from ) {
    if ( typeof from[k] === "function" ) {
      to[k] = from[k];
    }
  }
  return to;
}

/**
 * キーバインド
 * @param {Object} キーバインド
 * @param {Element} リスナを設定する要素
 */
util.KeyBind = function ( binding, e ) {
  this.binding = binding;
  var thiz = this;
  setEventListener( e, "keydown", function(ev) {
    thiz.handleKeyEvent(ev);
  });
}
util.KeyBind.prototype = {

  /**
   * キーイベントを処理する。
   */
  handleKeyEvent: function (e) {

    var keycode, modifier = "";

    // Mozilla(Firefox, NN) and Opera
    if (!Prototype.Browser.IE) {
      keycode = e.which;
      modifier = this.resolvModifier(e);
    // Internet Explorer
    } else {
      keycode = window.event.keyCode;
      modifier = this.resolvModifierIE(e);
    }

    // キーコードの文字を取得
    var keyStr = this.resolvKeyChar(keycode);
    keyStr = keyStr + modifier;

    // 処理を実行
    if ( this.binding[keyStr] && typeof this.binding[keyStr] == "function" ) {
      var stop = this.binding[keyStr](e);
      if ( stop ) {
	      // イベントの上位伝播を防止
	      if (e != null) {
	         e.preventDefault();
	         e.stopPropagation();
	      } else {
	         event.returnValue = false;
	         event.cancelBubble = true;
	      }
      }
    }
  },
  /**
   * モディファイアを示す文字列を生成する。
   * @param {Object} e イベント
   */
  resolvModifier: function(e){
    var str = ""
    if (this.isModified(e, "ctrlKey", Event.CONTROL_MASK)) {
      str = str + "+Ctrl";
    }
    if (this.isModified(e, "shiftKey", Event.SHIFT_MASK)) {
      str = str + "+Shift";
    }
    if (this.isModified(e, "altKey", Event.ALT_MASK)) {
      str = str + "+Alt";
    }
    if (this.isModified(e, "metaKey", Event.META_MASK)) {
      str = str + "+Meta";
    }
    return str;
  },
  /**
   * モディファイアを示す文字列を生成する。IE用
   * @param {Object} e イベント
   */
  resolvModifierIE: function(e){
    var str = ""
    if (event.ctrlKey) {
      str = str + "+Ctrl";
    }
    if (event.shiftKey) {
      str = str + "+Shift";
    }
    if (event.altKey) {
      str = str + "+Alt";
    }
    if (event.metaKey) {
      str = str + "+Meta";
    }
    return str;
  },
  /**
   * モディファイアが押されているか評価する。
   * @param {Object} e イベント
   * @param {Object} key フィールド名
   * @param {Object} mask マスク
   */
  isModified: function( e, key, mask ){
    var m = false;
    if (e != null) {
      m = typeof e.modifiers == 'undefined' ? e[key] : e.modifiers & mask;
    } else {
      m = event[key];
    }
    return m;
  },

  /**
   * キー文字列を取得する。
   */
  resolvKeyChar: function (keycode) {
    switch( keycode ) {
      case 13:
        return "Enter";
      case 27:
        return "Esc";
      case 8:
        return "BackSpace";
      case 9:
        return "Tab";
      case 32:
        return "Space";
      case 45:
        return "Insert";
      case 46:
        return "Delete";
      case 35:
        return "End";
      case 36:
        return "Home";
      case 33:
        return "PageUp";
      case 34:
        return "PageDown";
      case 38:
        return "↑";
      case 40:
        return "↓";
      case 37:
        return "←";
      case 39:
        return "→";
    }
    return String.fromCharCode(keycode).toUpperCase();
  }
}

/**
 * ボタン
 */
util.Button = function( id, imgName, action, alt, accesskey, enable, prefix, suffix ) {

  prefix = prefix || "./img/button_";
  suffix = suffix || ".gif";
  this.id = id;
  this.n = document.getElementById( this.id );

  this.imgName = imgName;
  this.action = action;

  // ボタン
  this.a = document.createElement("a");
  this.a.href = "javascript:void(0);";
  if (accesskey) { this.a.accessKey = accesskey; }
  this.n.appendChild( this.a );
  this.img = document.createElement("img");
  if (alt)  {
     this.img.alt = accesskey ? alt + "( " +accesskey+ " )" : alt;
     this.img.title =  this.img.alt;
  }
  this.img.src = prefix + this.imgName + suffix;
  this.img.style.width = this.n.style.width;
  var self = this;
  this.a.onclick = function() {
    if ( self.action ) { self.action.call( self ); }
  };
  this.n.onmouseover = function() {
	  self.img.src = prefix + self.imgName + "_over" + suffix;
  };
  this.n.onmouseout = function() {
  	self.img.src = prefix + self.imgName + suffix;
  };
  this.a.onfocus = this.n.onmouseover;
  this.a.onblur = this.n.onmouseout;
  this.a.appendChild( this.img );

  // グレーアウトしたボタン
  this.img_o = document.createElement("img");
  if (alt)  { this.img_o.alt = accesskey ? alt + "( " +accesskey+ " )" : alt; }
  this.img_o.src = prefix + this.imgName + "_gray" + suffix;
  this.img_o.style.display = "none";
  this.img_o.style.width = this.n.style.width;
  this.n.appendChild( this.img_o );

  this.setEnable(enable);
}
util.Button.prototype = {
  /**
   * 利用可/不可を更新する。
   */
  setEnable : function( enable ) {
    if ( enable ) {
      this.a.style.display = "inline";
      this.img_o.style.display = "none";
    } else {
      this.a.style.display = "none";
      this.img_o.style.display = "inline";
    }
  }
}

/**
 * メニュー
 */
util.Menu = function( id, imgName, action, alt, accesskey, enable, prefix, suffix ) {
  util.Button.call( this, id, imgName, action, alt, accesskey, enable, prefix, suffix );
  this.img_s = document.createElement("img");
  if (alt)  { this.img_o.alt = accesskey ? alt + "( " +accesskey+ " )" : alt; }
  this.img_s.src = prefix + this.imgName + "_s" + suffix;
  this.img_s.style.display = "none";
  this.n.appendChild( this.img_s );
}
util.Menu.prototype =util.merge( util.Button.prototype, {} );
util.Menu.prototype.select = function( select ) {
  if ( !select ) {
    this.a.style.display = "inline";
    this.img_s.style.display = "none";
  } else {
    this.a.style.display = "none";
    this.img_s.style.display = "inline";
  }
}

util.MenuBar = function( className, rootId, prefix, pageManager ) {
  this.className = className; // @Inject
  this.rootId = rootId; // @Inject
  this.prefix = prefix;
  this.pageManager = pageManager; //@Inject
  this.menus = [];
}
util.MenuBar.prototype = {

  // 初期化する
  initialize : function(defaultPage, action, param) {

    // メニュー
    this.menus = [];
    var self = this;
    var ms = document.getElementsByClassName(this.className, document.getElementById(this.rootId));
    for ( var i=0,n=ms.length;i<n;i++ ) {
       var id = ms[i].id;
       var b = new util.Menu ( id, id, action, ms[i].alt, null, true, "./img/", ".png" );
       this.menus.push( b );
    }
    if ( defaultPage ) {
      self.to( defaultPage, param );
    }
  },
  to : function( page, params ) {
    for ( var i=0,n=this.menus.length;i<n;i++ ) {
      var id = this.menus[i].id.replace(new RegExp(this.prefix + "\\_"), "" );
      if ( page == id || ( params && params["menuId"] && params["menuId"] == id)  ) {
        this.menus[i].select( true );
      } else {
        this.menus[i].select( false );
      }
    }
    this.pageManager.to( page, params );
  }
}

/**
 * タイマー
 * @param {Number} wait 待ち時間(ミリ秒)
 * @param {Function} action 実行する処理
 * @param {Boolean} once 一度だけ実行するか/繰り返し実行するか。一度だけ実行する場合true
 */
util.Timer = function (wait, action, once ) {
  this.wait = wait;
  this.action = action;
  this.id = null;
  this.once = once;
}

util.Timer.prototype = {

  /**
   * 開始
   */
  start: function () {
    if ( !this.id ) {
      if ( this.once ) {
         this.id = setTimeout(this.action, this.wait);
      } else {
         this.id = setInterval( this.action, this.wait );
      }
    }
  },
  /**
   * 停止
   */
  stop: function () {
    if ( this.id ) {
      clearInterval(this.id);
      this.id = null;
    }
  },
  /**
   * タイマーが起動しているか評価する
   */
  started: function() { return this.id != null; }
}

util.BasicTable = {
  setBasicActions : function (){
    var self = this;
    self.table.subscribe("rowMouseoverEvent", self.table.onEventHighlightRow);
    self.table.subscribe("rowMouseoutEvent", self.table.onEventUnhighlightRow);
    self.table.subscribe("rowClickEvent", self.table.onEventSelectRow);

    // リサイザーを強制的に利用可にする。
    var res = document.getElementsByClassName("yui-dt-resizer", self.elementId);
    for ( var i=0,n=res.length;i<n;i++ ) {
      res[i].style.height = "19px";
    }

    // ローディングを作成
    this.table_elm = document.getElementById(self.elementId);
    this.loading_elm = document.createElement('div');
    this.loading_elm.innerHTML = fx.template.Templates.common.loading;
    this.loading_elm.style.padding = "10px";
    this.loading_elm.style.display = "none";
    this.table_elm.parentNode.appendChild(this.loading_elm);
    this.loading(true);
  },
  loading : function( on ) {
    this.loading_elm.style.display = on ? "block" : "none";
    this.table_elm.style.display = on ? "none" :  "block";
  },
  setData: function( data ) {
    if ( this.length() > 0 ) {
      this.table.deleteRows( 0, this.length() );
    }
    this.table.addRows(data);
    if ( this.sortBy ) {
      this.table.sortColumn(  this.table.getColumn( this.sortBy) );
    }
  },
  length : function() {
    return this.table.getRecordSet().getLength();
  },
  add: function( data ) {
    this.table.addRow(data);
  },
  remove: function( data ) {
    this.table.deleteRow(data);
  },
  update: function( row, data ) {
    this.table.updateRow( row, data );
  }
}

/**
 * 日時を「YY-MM-DD HH:mm:ss」形式にフォーマットします。
 */
util.formatDate = function( d ) {
  return "" + d.getFullYear() + "-" +  util.fillZero( (d.getMonth()+1), 2) + "-"
      + util.fillZero( d.getDate(), 2) + " " + util.fillZero( d.getHours(), 2) + ":"
      + util.fillZero( d.getMinutes(), 2) + ":" + util.fillZero( d.getSeconds(), 2);
}
util.fillZero = function( number, size ) {
  var s = number != 0 ? Math.log( number ) * Math.LOG10E : 0;
  for( i=1,n=size-s,str="";i<n;i++ ) str += "0";
  return str+number;
}

/**
 * リスナ
 */
util.Listener = function() {
  this.listener = {};
}
util.Listener.prototype = {
  addListener : function( type, listener ) {
    this.getListeners( type ).push( listener );
  },
  removeListener : function( type, listener ) {
    var tmp = [];
    var list = this.getListeners(type);
    for( var i=0,n=list.length;i<n;i++ ) {
      if ( list[i] != listener ) tmp.push( listener );
    }
    this.listener[type] = tmp;
  },
  getListeners : function( type ) {
    if ( !this.listener[type] ) {
      this.listener[type] = [];
    }
    return this.listener[type];
  },
  fire : function( type, event, f ) {
    var list = this.getListeners(type);
    for( var i=0,n=list.length;i<n;i++ ) {
      if ( f ) {
        if ( typeof f == "function" ) {
          f.call( null, list[i], event );
        } else {
          list[i][f]( event );
        }
      } else {
        list[i].call( null, event );
      }
    }
  }
}

/**
 * トピックパス
 */
util.TopicPath = function( id ) {
  //this.elementId = id;
}
util.TopicPath.prototype = {
  set: function( path ) {
    var el = document.getElementById( this.elementId );
    if ( path ) {
      el.innerHTML =  "<li>" + path.escapeHTML().split(":").join("</li><li>") + "</li>";
    } else {
      el.innerHTML = "";
    }
  }
}

/**
 * 日付入力UI
 */
util.DateInput = function(elementId, title, start, end ) {
  this.elementId = elementId;
  this.title = title;
  this.dialog;
  this.calendar;
  this.start = start;
  this.end = end;
  this.listener = new util.Listener();
}
util.DateInput.prototype = {

  template : new Template(
      '<div style="width:700px;">'+
      '  <div style="float:left;width:50px;">#{title}</div>'+
      '  <div style="float:left;">'+
      '    <input style="width:270px;float:left;" type="text" id="#{elementId}_date_input" name="#{elementId}_date_input" value="" />'+
      '    <div style="float:left;margin-left:5px;">' +
      '      <div id="#{elementId}_button" class="button" style="margin-right:0px;"></div>' +
      '      <div class="dateinput_panel" id="#{elementId}_panel">' +
      '          <div class="dateinput_cal" id="#{elementId}_cal"></div>' +
      '      </div>' +
      '      </div>'+
      '    </div>'+
      '  <div class="breaker"></div>'+
      '</div>'),

  initialize : function() {
    var self = this;
    var el = document.getElementById( this.elementId );
    el.innerHTML = this.template.evaluate( {
      elementId: this.elementId,
      title: this.title.escapeHTML()
    } );
    this.calendar = new YAHOO.widget.Calendar(this.elementId+"_cal", {
        iframe:false,          // Turn iframe off, since container has iframe support.
        hide_blank_weeks:true  // Enable, to demonstrate how we handle changing height, using changeContent
    });

    // 日本語化
    this.calendar.cfg.setProperty("MDY_YEAR_POSITION", 1);
    this.calendar.cfg.setProperty("MDY_MONTH_POSITION", 2);
    this.calendar.cfg.setProperty("MDY_DAY_POSITION", 3);
    this.calendar.cfg.setProperty("MY_YEAR_POSITION", 1);
    this.calendar.cfg.setProperty("MY_MONTH_POSITION", 2);

    this.calendar.cfg.setProperty("MONTHS_SHORT",   ["1\u6708", "2\u6708", "3\u6708", "4\u6708", "5\u6708", "6\u6708", "7\u6708", "8\u6708", "9\u6708", "10\u6708", "11\u6708", "12\u6708"]);
    this.calendar.cfg.setProperty("MONTHS_LONG",    ["1\u6708", "2\u6708", "3\u6708", "4\u6708", "5\u6708", "6\u6708", "7\u6708", "8\u6708", "9\u6708", "10\u6708", "11\u6708", "12\u6708"]);
    this.calendar.cfg.setProperty("WEEKDAYS_1CHAR", ["\u65E5", "\u6708", "\u706B", "\u6C34", "\u6728", "\u91D1", "\u571F"]);
    this.calendar.cfg.setProperty("WEEKDAYS_SHORT", ["\u65E5", "\u6708", "\u706B", "\u6C34", "\u6728", "\u91D1", "\u571F"]);
    this.calendar.cfg.setProperty("WEEKDAYS_MEDIUM",["\u65E5", "\u6708", "\u706B", "\u6C34", "\u6728", "\u91D1", "\u571F"]);
    this.calendar.cfg.setProperty("WEEKDAYS_LONG",  ["\u65E5", "\u6708", "\u706B", "\u6C34", "\u6728", "\u91D1", "\u571F"]);

    this.calendar.cfg.setProperty("MY_LABEL_YEAR_POSITION",  1);
    this.calendar.cfg.setProperty("MY_LABEL_MONTH_POSITION",  2);
    this.calendar.cfg.setProperty("MY_LABEL_YEAR_SUFFIX",  "\u5E74");
    this.calendar.cfg.setProperty("MY_LABEL_MONTH_SUFFIX",  "");

    // 利用可能な範囲を示すレンダーを設定
    var s = new Date( this.start );
    var e = new Date( this.end );
    this.calendar.addRenderer( s.getFullYear()  + "/" + (s.getMonth()+1) + "/" + s.getDate() +"-" +
        e.getFullYear()  + "/" + (e.getMonth()+1) + "/" + e.getDate(), this.calendar.renderCellStyleHighlight1);

    this.calendar.render();

    // クリックされたらダイアログを閉じる。
    this.calendar.selectEvent.subscribe(function() {
       if (self.calendar.getSelectedDates().length > 0) {
            var selDate = self.calendar.getSelectedDates()[0];
            document.getElementById( self.elementId+"_date_input" ).value =
              selDate.getFullYear() + "-" + util.fillZero( (selDate.getMonth()+1), 2) + "-" + util.fillZero( selDate.getDate(),2);
       }
       self.hide();
       self.listener.fire( "selected", {date: self.getDate()} );
    });

    // ボタン
    this.button = new util.Button( this.elementId + "_button", "calendar", function() {
      self.show();
    }, "カレンダーを表示");
    this.button.setEnable( true );
    YAHOO.util.Event.addListener( document.getElementById( this.elementId +"_date_input") , "blur", function( ev ) {
      self.listener.fire( "blur", {date: self.getDate()} );
    });
    YAHOO.util.Event.addListener(document.body, "click", function( ev ) {
      if ( self.visible ) {
        var target = YAHOO.util.Event.getTarget( ev );
        while( target ) {
          if ( target.id == self.elementId ) { return; }
          target = target.parentNode;
        }
        self.hide();
      }
    } );
    self.hide();
  },
  show: function() {
    document.getElementById(this.elementId + "_cal").style.visibility = "visible";
    this.visible = true;
  },
  hide: function() {
    document.getElementById(this.elementId + "_cal").style.visibility = "hidden";
    this.visible = false;
  },
  destroy: function() {
    document.getElementById(this.elementId).innerHTML = "";
  },
  getDate : function() {
    var text = document.getElementById( this.elementId+"_date_input" ).value;
    if ( !text ) return null;
    var matches = text.match( /^(\d{4})\-(\d{1,2})-(\d{1,2})$/ );
    if ( !matches ) return null;
    return new Date( Number( matches[1] ), Number( matches[2]-1 ), Number( matches[3] ));
  }
}


/**
 * SWFを取得する。
 */
util.getSwf = function( name ) {
  if (navigator.appName.indexOf("Microsoft") != -1) {
     return window[name];
  } else {
     return document[name];
  }

}

/**
 * 色選択UI
 */
util.ColorPicker = function(elementId, color,callback) {
  this.elementId = elementId;
  this.color = color;
  this.callback = callback;
}
util.ColorPicker.prototype = {
  body:  new Template(
      '<div class="picker">' +
      ' <div class="picker_thumb" id="picker_thumb_#{id}"></div>'+
      ' <div class="picker_picker" id="picker_picker_#{id}">#{body}</div>'+
      '</div>'),
  init: function() {
    var self = this;
    var top = "<table id='picker_table_" + this.elementId +  "' class='picker' cellpading=0 cellspacing=0><tr>";
    var bottom = "";
    var current = top;
    var list = ["11","33","55","77","99","BB","DD","FF"];
    for ( var g=0,gn=list.length;g<gn;g++  ) {
      for ( var r=0,rn=list.length;r<rn;r++  ) {
        for ( var b=0,bn=list.length;b<bn;b++  ) {
          var c = list[r] + list[g] +list[b];
          str = '<td><div class="block" style="background-color:#' + c + ';border:1px solid #' + c + ';"></div></td>'
          if ( r <= 3 ) {
            top += str;
          } else {
            bottom+=str;
          }
        }
        if (r ==3) { top += "</tr><tr>";  }
      }
      bottom += "</tr><tr>";
    }
    var body = top + bottom + "</tr></table>";
    var el = document.getElementById( this.elementId );
    el.innerHTML = this.body.evaluate( {
      id:this.elementId,
      body:body
    } );

    var thumb = document.getElementById( "picker_thumb_" + this.elementId );
    thumb.style.backgroundColor = this.color;
    thumb.onclick = function( ev ) {
      self.show();
      return false;
    }

    // イベントを割り当て
    var blocks = document.getElementById("picker_table_" + this.elementId ).getElementsByTagName( "div" );
    var enter = function() {
      thumb.style.backgroundColor = this.style.backgroundColor;
      this.style.border = "1px solid #FFFFFF ";
    }
    var out = function() {
      thumb.style.backgroundColor = self.color;
      this.style.border = "1px solid " + this.style.backgroundColor;
    }
    var click = function() {
      thumb.style.backgroundColor = this.style.backgroundColor;
      self.color =  this.style.backgroundColor;
      if ( self.callback ) {
        self.callback.call( null, self.color );
      }
    }
    for ( var i=0,n=blocks.length;i<n;i++ ) {
      if ( blocks[i] == el  ) { continue; }
// IE7だとリスナ登録がやたら遅いので、直接イベントハンドラを割り当てる。
//      YAHOO.util.Event.addListener(blocks[i], "mouseover", enter);
//      YAHOO.util.Event.addListener(blocks[i], "mouseout", out);
//      YAHOO.util.Event.addListener(blocks[i], "click", click);
      blocks[i].onmouseover=enter;
      blocks[i].onmouseout=out;
      blocks[i].onclick=click;
    }

    YAHOO.util.Event.addListener(document.body, "click", function( ev ) {
      if ( self.visible &&  YAHOO.util.Event.getTarget( ev ) != thumb ) {
        self.hide();
      }
    } );
  },
  show: function() {
    document.getElementById("picker_picker_" + this.elementId).style.visibility = "visible";
    this.visible = true;
  },
  hide: function() {
    document.getElementById("picker_picker_" + this.elementId).style.visibility = "hidden";
    this.visible = false;
  },
  get : function() {
    return this.convert(this.color);
  },
  convert: function(str) {
    if ( str.match(/^\#[0-9A-Fa-f]{6}$/) ) {
      return str;
    } else if ( str.match(/^\#([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])$/) ) {
      return "#" + RegExp.$1+RegExp.$1+RegExp.$2+RegExp.$2+RegExp.$3+RegExp.$3;
    } else if (str.match(/^rgb\(\s*(\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\s*\)$/)) {
      return "#" + this.toHex(RegExp.$1)+this.toHex(RegExp.$2)+this.toHex(RegExp.$3);
    } else {
      throw "illegal color format. color=" + str;
    }
  },
  toHex: function( str ) {
    var h = Number(str).toString(16);
    return h.length == 1 ? "0"+h : h;
  }
}

///**テンプレートに、引数の文字列をエスケープする機能を追加*/
//Template.prototype.evaluate_org = Template.prototype.evaluate;
//Template.prototype.evaluate = function( object ) {
//  for( var i in object ) {
//    if ( Object.isFunction(object[i].escapeHTML) ) {
//      object[i] = object[i].escapeHTML();
//    }
//  }
//  return this.evaluate_org( object );
//}

/***
 * パス文字列の操作
 */
util.PathUtils = {
  /**
   * 末尾の"/"以降の名前を取得する
   */
  basename : function(path) {
    if (!path) return "";
    var i = path.lastIndexOf("/");
    if (i < 0 ) return path;
    if (i+1 >= path.length ) return "";
    return path.substring( i+1 );
  },
  /**
   * 末尾の"/"以前の名前を取得する
   */
  dirname : function(path) {
    if (!path) return "";
    var i = path.lastIndexOf("/");
    if (i <= 0 ) return "";
    return path.substring( 0, i );
  },
  /**
   * 指定ディリクトリ配下のファイル/フォルダであるか評価する
   * @param path {String} 評価対象のパス
   * @param dir {String} 親ディレクトリ
   * @return {Boolean} 親ディレクトリの配下の要素であればtrue
   */
  isChild : function( path, dir ) {
    return path.startsWith( dir + "/" );
  },
  /**
   * パスの配列を探索し、親とその子が含まれていれば、親だけを残す。
   * @param paths {Array:String} パスの配列
   * @return {Array:String} 親のみのパス
   */
  normarize : function(paths) {
    var result = [];
    paths = paths.sortBy( function( value ) { return value.length; } );
    for ( var j=0;j<paths.length;j++ ) {
      var isChild = false;
      for ( var i=0;i<result.length;i++ ) {
        if ( util.PathUtils.isChild( paths[j], result[i] ) ) {
          isChild = true;
          break;
        }
      }
      if (!isChild) result.push( paths[j] );
    }
    return result;
  }
}

/**基本の例外ハンドラ*/
util.BasicExceptionHandler = function( error, detail, option ) {
  // エラーコードがない場合はメッセージをそのまま積む。
  if ( !detail.code ) return error;
  switch ( detail.code ) {
    case "not_found": 
      return fx.template.Templates.common.errorMsg.notFound.evaluate( option );
    case "already_exist": 
      return fx.template.Templates.common.errorMsg.alreadyExist;
    case "is_not_file": 
      return fx.template.Templates.common.errorMsg.isNotFile;
    case "is_not_folder": 
      return fx.template.Templates.common.errorMsg. isNotFolder;
    case "illegal_name":
      return fx.template.Templates.common.errorMsg.illegalName.evaluate( option );
    case "illegal_arguments":
    case "fatal":
      return fx.template.Templates.common.errorMsg.systemError;
    case "not_connected":
      return fx.template.Templates.common.errorMsg.serverError;
    default:
      return error;
  }
}

// クリックタイマー
util.ClickTimer = function( id, callback ) {
  this.id = null;
  this.elm = document.getElementById( id );
  this.buff = [];
  this.timer = null;
  this.clicked = false;
  this.callback = callback;
  var self = this;
  Event.observe(document.getElementById( id ), 'mouseup', function(ev) { // prototype.jsに依存
    self.onClicked( ev );
  });
}
util.ClickTimer.prototype = {
  onClicked : function(ev) {
    if ( !this.timer ) {
      this.buff.push( true );
      var self = this;
      this.timer = window.setInterval(function ( ) {
        self.check();
      }, 250);
    } else {
      this.clicked = true;
    }
  }, 
  check : function() {
    this.buff.push( this.clicked );
    this.clicked = false;
    if ( this.isEnd() ) {
      try {
        if ( this.callback ) this.callback.call( null, this.buff.slice( 0, this.buff.length-1 ) );
      } finally {
        window.clearTimeout( this.timer );
        this.timer = null;
        this.buff = [];
      }
    }
  },
  isEnd : function() {
    if (this.buff.length <= 2) return false;
    for( var i=0,n=this.buff.length-1; i<2; i++ ) {
      if ( this.buff[n-i] == true ) return false;
    }
    return true;
  }
}

/**制御文字*/
util.CONTROLL_CODE = /[\x00-\x1F\x7F]/
