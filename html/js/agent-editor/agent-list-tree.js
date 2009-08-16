// ネームスペース
namespace( "fx.ui" );

//エージェント一覧ツリー
fx.ui.AgentFileListTree = function() {
  this.elementId = null; // @Inject
  this.agentEditor = container.Inject;
  this.tree = null; // YUI Tree
  this.nodeId = 0; // ノードの連番
}
fx.ui.AgentFileListTree.prototype = {
  init : function() {
    if ( this.tree )  return
    
    this.tree = new YAHOO.widget.TreeView(this.elementId);

    this.createBranch( {name:"エージェント", path:fx.constants.AGENTS_DIR, type:"directory"},
        null, false, this.listFiles, true );
    this.createBranch( {name:"共有ライブラリ", path:fx.constants.SHARED_LIB_DIR, type:"directory"},
        null, false, this.listFiles, true );
    this.tree.draw();
    var self = this;
    this.tree.subscribe( "clickEvent", function( ev, node ) {
      return  self.onClick( ev );
    } );
  },
  /**
   * 枝ノードを追加する。
   * @param {Object} data 枝ノードのデータ
   * @param {Object} parent 親ノード。nullの場合rootに追加
   * @param {boolean} insertFirst ノードの最初に追加するか?falseの場合末尾に追加。
   * @param {Function} provider 次の一覧を返す関数 nullの場合、子を持たない。
   * @param {boolean} expand 枝を開くかどうか
   */
  createBranch: function( data, parent, insertFirst, provider, expand  ) {
    var thiz = this;
    if ( !parent ) parent = this.tree.getRoot();

    var id = this.nodeId++;
    var node = new YAHOO.widget.HTMLNode(
      this.createNode(data, id), null, false, true);
    node.data = {"node-id":"node:"+id, data:data, path:data.path};
    data.id = id;
    
    if ( provider ) {
      node.setDynamicLoad (function(parentNode, onCompleteCallback) {
        provider.call( thiz, parentNode, onCompleteCallback);
      });
    }
    if ( insertFirst && parent.hasChildren(false) ) {
      node.insertBefore(parent.children[0]);
    } else {
      parent.appendChild(node);
    }
    if ( this.visible ) {
      parent.refresh();
      parent.expand();
    }
    if ( provider && expand ) {
      node.expand();
    }
    return node;
  },
  /**
   * ノードを作成する
   */
  createNode : function(data, id) {
    var type = data.type;
    if ( data.path == fx.constants.AGENTS_DIR ) type = "agents";
    if ( data.path == fx.constants.SHARED_LIB_DIR ) type = "shared_lib";
    return fx.template.Templates.agentEditor.tree.node.evaluate( {
      name : data.name,
      id : id,
      type : type,
      selected : this.agentEditor.isSelected( data.path ) ? "selected" : ""
    });
  },
  /**
   * 子要素を一覧する
   */
  listFiles : function(parentNode, onCompleteCallback) {
    var self = this;
    var data = parentNode.data;
    this.agentEditor.list( data.data.path, function( list ) {
      for(var i=0,l=list.length;i<l;i++) {
        var childData = list[i];
        self.createBranch( childData,parentNode, false,
            childData.type == "directory" ? self.listFiles : null, false );
      }
      onCompleteCallback();
    }, function() {
      onCompleteCallback();
    });
  },

  /**
   * ノードを破棄する
   */
  remove: function( id ) {
    var node = this.findNodeById( id );
    if ( node ) {
      var p = node.parent;
      this.tree.removeNode( node, true );
      if ( p && !p.hasChildren(false) ) {
        p.expanded = false;
      }
    }
  },

  /**
   * ノードの表示内容を更新する
   */
  updateNode: function( path ) {
    var node = this.tree.getNodeByProperty( "path", path );
    var expanded = node.expanded;
    this.tree.removeChildren( node );
    if ( expanded ) node.expand();
  },

  /**
   * ツリーを描画する。
   */
  draw: function() {
    this.tree.draw();
    this.visible = true;
  },
  /**
   * ノードを順に特定するインデックスを作る。
   */
  createIndex : function( node, buff ) {
    if ( node.parent ) this.createIndex( node.parent, buff );
    buff.push( node.index );
    return buff;
  },
  /*
   * クリックされたら呼び出される。
   */
  onClick : function(ev) {
    var data = ev.node.data.data;
    if (!data.index) data.index = this.createIndex( ev.node, [] );

//    if ( !this.prevSelect )  {
//      this.prevSelect = { time : new Date().getTime(), target:data.path };
//    } else {
//      var diff = new Date().getTime() - this.prevSelect.time;
//      if ( this.prevSelect.target == data.path 
//          && diff > 300 && diff < 600 ) {
//        //  リネーム開始
//        if ( data.path == "agents" || data.path == "shared_lib" ) return false;
//        this.agentEditor.clear();
//        this.agentEditor.select(data);
//        editNode();
//        return false;
//      }
//      this.prevSelect = null;
//    }
    
    // 選択変更
    // 選択がない
    if ( ev.event.ctrlKey ) {
      // CTRL + クリック
      if ( this.agentEditor.isSelected( data.path ) ) {
        this.agentEditor.unselect(data);
      } else {
        this.agentEditor.select(data);
      }
      this.rangeSelectStart = null;
    } else if ( ev.event.shiftKey ) {
      // SHIFT + クリック
      var selections = this.agentEditor.getSelections();
      // 基点が決まっていない場合、基点を決める
      if ( !this.rangeSelectStart  ) {
        if ( selections.size() > 0 ) {
          // 選択されているアイテムの中で一番上のものを範囲選択の基点とする。
          selections =  this.sortByIndex(selections);
          this.rangeSelectStart = selections[0]; 
        } else {
          // 選択がなければ、クリックと同じ動作
          this.agentEditor.clear();
          this.agentEditor.select(data);
          this.rangeSelectStart = null;
        }
      }
      // 基点から、クリックした位置までの要素を選択。
      this.agentEditor.clear();
      var range = this.sortByIndex([this.rangeSelectStart,data]);
      var current = this.findNodeByPath( range[0].path ); 
      var end = this.findNodeByPath( range[1].path );
      while( current && current != end ) {
        var tmp = current.data.data;
        if (!tmp.index) tmp.index = this.createIndex( current, [] );
        this.agentEditor.select(tmp);
        if ( current.expanded && current.children.length > 0 ) {
          current = current.children[0];
          continue;
        }
        if (current.nextSibling) { 
          current = current.nextSibling;
          continue;
        }
        tmp = current.parent;
        current = null;
        while ( tmp ) {
          if ( tmp.nextSibling ) {
            current = tmp.nextSibling;
            break;
          } else {
            tmp = tmp.parent;
          }
        }
      }
      if ( current ) {
        var tmp = current.data.data;
        if (!tmp.index) tmp.index = this.createIndex( current,[] );
        this.agentEditor.select(tmp);
      }
    } else {
      this.agentEditor.clear();
      this.agentEditor.select(data);
      this.rangeSelectStart = null;
    }
    return false;
  },
  
  sortByIndex : function( array ) {
    return array.sort( function( a,b ) {
      var n = Math.min( a.index.length, b.index.length );
      for ( var i=0; i<n; i++ ) {
        var x =  a.index[i] - b.index[i];
        if (x != 0) return x; 
      }
      return a.index.length - b.index.length
    } );
  },
  /**
   * パスに対応するノードを検索する。
   * @param {String} path パス
   * @return パスに対応するノード
   */
  findNodeByPath: function( path ) {
    return this.tree.getNodeByProperty( "path", path );
  },
  /**
   * IDに対応するノードを検索する。
   * @param {String} nodeId ノードID
   * @return IDに対応するノード
   */
  findNodeById: function( nodeId ) {
    return this.tree.getNodeByProperty( "node-id", "node:" + nodeId );
  }
}