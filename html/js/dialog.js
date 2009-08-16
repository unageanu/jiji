// ネームスペース
namespace( "util" );

util.Dialog = function() {

  this.dialog = document.createElement('div');
  this.dialog.id = 'dialog';
  this.dialog.innerHTML =
      "<div id='dialog-header'>"
    + "  <div id='dialog-title'></div>"
    + "  <div id='dialog-close'></div>"
    + "</div>"
    + "<div id='dialog-body'>"
    + "  <div id='dialog-content'>"
    + "  </div>"
    + "  <div id='dialog-separator'>"
    + "  </div>"
    + "  <div>"
    + "    <div id='dialog-buttons'>"
    + "    </div>"
    + "    <div style='clear:both;'/>"
    + "  </div>"
    + "</div>";
  document.body.appendChild(this.dialog);
  this.header = document.getElementById("dialog-header");
  this.title = document.getElementById("dialog-title");
  this.content = document.getElementById("dialog-content");
  this.buttons = document.getElementById("dialog-buttons");
  
  var self = this;
  this.close = document.getElementById("dialog-close");
  this.close.onclick = function() {
    self.hideDialog();
  };
  this.mask = document.createElement('div');
  this.mask.id = 'dialog-mask';
  document.body.appendChild(this.mask);

  this.dialog.style.visibility = "hidden";
  this.mask.style.visibility = "hidden";
  this.keybind =  new util.KeyBind( {}, this.dialog ) ;
}
util.Dialog.prototype = {
  TIME : 10,
  SPEED : 25,
  WRAPPER : 'content',

  show : function( type, params ) {
    if(!type) {
    	type = 'input';
     }

    // ダイアログを初期化
    this.content.innerHTML = params.message;
    if ( params.headerVisible ) {
	    if ( params.title ) {
	    	this.title.innerHTML = params.title;
	    }
	    this.close.style.display = "block";
    } else {
    	this.header.style.display = "none";
    }
    
    var bind = { "Tab" : function(){} }; 
    this.buttons.innerHTML = "";
    if ( params.buttons ) {
    	for ( var i = 0; i < params.buttons.length ; i++ ) {
    		this.createButton( params.buttons[i], bind );
    	}
    } else {
    	this.createButton( {
    		id : "close", 
    		type : "close",
    		accesskey: "C",
    	  key: "Enter"}, bind);
    }
    this.keybind.binding = bind; 
    
    // ダイアログを表示
    this.mask.style.visibility = "visible";
    this.dialog.style.visibility = "visible";
    
    this.dialog.style.opacity = .00;
    this.dialog.style.filter = 'alpha(opacity=0)';
    this.dialog.alpha = 0;

		var width = this.pageWidth();
		var height = this.pageHeight();
		var left = this.leftPosition();
		var top = this.topPosition();
	
		var dialogwidth = this.dialog.offsetWidth;
		var dialogheight = this.dialog.offsetHeight;
		var topposition = top + (height / 3) - (dialogheight / 2);
		var leftposition = left + (width / 2) - (dialogwidth / 2);
	
		this.dialog.style.top = topposition + "px";
		this.dialog.style.left = leftposition + "px";
		this.dialog.className = type + " dialog";

    var content = document.getElementById(this.WRAPPER);
    this.mask.style.height = content.offsetHeight + 'px';
    var self = this;
    // すでに変化中であれば一旦停止
    if ( this.timer != null ) {
      clearInterval(this.timer);
      // コントロールの無効化はすでにされているので行わない。
    } else {
      // リンクとコントロールを無効化
      this.cache = [];
      var f = function( elms ) {
        for( var i = 0 ; i < elms.length; i++ ) {
          var old = { 
              target: elms[i],
              disabled: elms[i].disabled, 
              accesskey: elms[i].accessKey,
              tabIndex : elms[i].tabIndex
          };
          elms[i].disabled = true;
          elms[i].accessKey = null;
          elms[i].tabIndex = -1;
          self.cache.push( old );
        }
      } 
      this.eachElements( "input", f);
      this.eachElements( "textarea", f);
      this.eachElements( "a", f);
      this.eachElements( "object", function(elms){ 
        for( var i = 0 ; i < elms.length; i++ ) {
          elms[i].style.visibility = "hidden";
        }
      });
    }
    this.timer = setInterval(function(){ self.fadeDialog(1); }, this.TIME);
    var as = this.buttons.getElementsByTagName( "a" );
    if ( as && as[0] ) { as[0].focus(); }
    if ( params.init ) {
      params.init.call( null, this );
    }
  }, 

  createButton: function( params, keybind ) {
  	
    var type = params["type"];
    var a = params["action"];
  	var action = function() {
      if ( a ) { 
      	if ( a.call( null, self  ) == false ){
          return;
        }
      }
      self.hideDialog();
    }; 
	  var b = document.createElement('div');
	  b.className= params["key"] == "Enter" ? "button default " + type  : "button " + type;
	  b.id = "dialog_" + type;
    this.buttons.appendChild(b);
    
    var self = this;
    var button = new util.Button("dialog_" + type, 
    		type, action, params["alt"], params["accesskey"]);
    button.setEnable( true );
    
    if(params["key"]) keybind[params["key"]] = action;
  },

  //ダイアログを非表示にする。
  hideDialog : function () {
    clearInterval(this.timer);
    var self = this;
    this.timer = setInterval( function(){ self.fadeDialog(0); } , this.TIME);
  },

  fadeDialog : function (flag) {
    if(flag == null) {
      flag = 1;
    }
    var value;
    if(flag == 1) {
      value = this.dialog.alpha + this.SPEED;
    } else {
      value = this.dialog.alpha - this.SPEED;
    }
    this.dialog.alpha = value;
    this.dialog.style.opacity = (value / 100);
    this.dialog.style.filter = 'alpha(opacity=' + value + ')';
    if(value >= 99) {
      clearInterval(this.timer);
      this.timer = null;
    } else if(value <= 1) {
      // リンクとコントロールを有効化
    	for( var i = 0 ; i < this.cache.length; i++ ) {
    		var c = this.cache[i];
    		c.target.accesskey = c.accesskey;
    		c.target.tabIndex = c.tabIndex;
    		c.target.disabled = c.disabled;
    	}
    	
      this.eachElements( "object", function(elms){ 
        for( var i = 0 ; i < elms.length; i++ ) {
          elms[i].style.visibility = "visible";
        }
      });
    	
      this.keybind.binding = {};
      
      this.dialog.style.visibility = "hidden";
      this.mask.style.visibility = "hidden";
      clearInterval(this.timer);
      this.timer = null;
    }
  },
  
  eachElements: function ( tag, f ) {
  	var elements = document.body.childNodes;
  	for( var i = 0; i < elements.length; i++  ) { 
  		if ( elements[i] != this.dialog && elements[i].getElementsByTagName ) {
  			var elms = elements[i].getElementsByTagName( tag );
  			f(elms);
  		}
  	}
  },
  
  /**
   * ウインドウの幅
   */
  pageWidth: function pageWidth() {
    if ( window.innerWidth != null  ) {
      return window.innerWidth;
    } else if ( document.documentElement && document.documentElement.clientWidth ) {
      return document.documentElement.clientWidth;
    } else if ( document.body != null  ) {
      return document.body.clientWidth;
    }
    return null;
  },

  /**
   * ウインドウの高さ
   */
    pageHeight: function () {
      if ( window.innerHeight != null  ) {
      return window.innerHeight;
    } else if ( document.documentElement && document.documentElement.clientHeight ) {
      return document.documentElement.clientHeight;
    } else if ( document.body != null  ) {
      return document.body.clientHeight;
    }
      return null;
    },

  /**
   * 縦方向スクロールの位置
   */
    topPosition: function() {
      if ( typeof window.pageYOffset != 'undefined') {
        return window.pageYOffset;
      } else if ( document.documentElement && document.documentElement.scrollTop ) {
        return document.documentElement.scrollTop;
      } else if ( document.body.scrollTop ) {
        return document.body.scrollTop;
      }
      return 0;
    },

  /**
   * 横方向スクロールの位置
   */
  leftPosition: function() {
    if ( typeof window.pageXOffset != 'undefined') {
      return window.pageXOffset;
    } else if ( document.documentElement && document.documentElement.scrollLeft ) {
      return document.documentElement.scrollLeft;
    } else if ( document.body.scrollLeft ) {
      return document.body.scrollLeft;
    }
    return 0;
  }
}