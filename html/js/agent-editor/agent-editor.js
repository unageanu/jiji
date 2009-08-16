// ネームスペース
namespace( "fx" );

// エージェントエディタコントローラ
fx.AgentEditor = function() {
  this.agentServiceStub = container.Inject;
  this.selections = new Hash({});
  this.listeners = new util.Listener();

  this.agentChangeListeners = container.Injects(
    container.types.has( "onAgentChanged" ) );
  this.selectionChangeListeners = container.Injects(
    container.types.has( "onAgentSelectionChanged" ) );
}
fx.AgentEditor.prototype = {

  EVENTS : {
    // 特定のパス配下の一覧が更新された
    CHANGED : "changed",
    // 選択が変更された
    SELECTION_CHANGED : "selection_changed"
  },

  /**
   * インスタンスを初期化する
   */
  init : function() {
    for (var i=0;i<this.agentChangeListeners.length;i++) {
      this.listeners.addListener( this.EVENTS.CHANGED, this.agentChangeListeners[i] );
    }
    for (var i=0;i<this.selectionChangeListeners.length;i++) {
      this.listeners.addListener( this.EVENTS.SELECTION_CHANGED,  this.selectionChangeListeners[i]);
    }
  },

  /**
   * 指定されたパスのファイル一覧を取得する。
   * @param path {String} パス
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  list : function( path, success, fail ) {
    this.agentServiceStub.list_files( path, success, fail);
  },
  /**
   * 指定されたパスのファイル内容を取得する。
   * @param path {String} パス
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  get : function( path, success, fail ) {
    this.agentServiceStub.get_file( path, success, fail );
  },
  /**
   * 指定されたパスの内容を更新する。
   * @param path {String} パス
   * @param body {String} 本文
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  put : function( path, body, success, fail ) {
    this.agentServiceStub.put_file( path, body, success, fail );
  },
  /**
   * 選択されたフォルダ配下にファイルを追加する。
   * @param path {String} パス
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  add : function( name, success, fail ) {
    if ( !this.enable("add") ) {
      if ( fail) fail( {msg:fx.template.Templates.common.errorMsg.systemError} );
      return;
    }
    var parent = this.selections.keys()[0];
    var path =  null;
    try {
      path = parent + "/" + this.checkName( name, parent, true );
    } catch ( ex ) {
      if ( fail) fail( ex );
      return;
    }
    var self = this;
    this.agentServiceStub.add_file( path, "", function(result){
      if (success) success(result);
      self.listeners.fire( self.EVENTS.CHANGED, {paths:[util.PathUtils.dirname(path)]}, "onAgentChanged" );
    }, function( error, detail ) {
      if ( fail) fail( {msg:util.BasicExceptionHandler( error, detail, 
            {name:fx.template.Templates.common.item.file} )} );
    } );
  },
  /**
   * 選択されたフォルダ配下にフォルダを追加する。
   * @param path {String} パス
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  mkcol : function( name, success, fail ) {
    if ( !this.enable("mkcol") ) {
      if ( fail) fail( {msg:fx.template.Templates.common.errorMsg.systemError} );
      return;
    }
    var parent = this.selections.keys()[0];
    var path =  null;
    try {
      path = parent + "/" + this.checkName( name, parent, false );
    } catch ( ex ) {
      if ( fail) fail( ex );
      return;
    }
    var self = this;
    this.agentServiceStub.mkcol( path, function(result){
      if (success) success(result);
      self.listeners.fire( self.EVENTS.CHANGED, {paths:[util.PathUtils.dirname(path)]}, "onAgentChanged" );
    }, function( error, detail ) {
      if ( fail) fail( {msg:util.BasicExceptionHandler( error, detail, 
          {name:fx.template.Templates.common.item.directory} )} );
    });
  },
  /**
   * 選択されたファイル/フォルダを削除する。
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  removeSelections : function( success, fail ) {
    if ( !this.enable("removeSelections") ) {
      if ( fail) fail( {msg:fx.template.Templates.common.errorMsg.systemError} );
      return;
    }
    var self = this;
    var targets = util.PathUtils.normarize(this.selections.keys());
    this.agentServiceStub.remove( targets, function(result){
      // 失敗した項目のメッセージを変換
      for ( var i in result.failed ) {
        result.failed[i].msg = util.BasicExceptionHandler( result.failed[i].msg, result.failed[i], { 
          name: self.selections.get([i]) && self.selections.get([i]).type == "directory" 
            ? fx.template.Templates.common.item.directory
            : fx.template.Templates.common.item.file} );
      }
      if (success) success(result);

      // 削除された文書orその配下要素は全て選択解除
      var newSelection =  new Hash({});
      var toggled =  [];
      self.selections.each(function(pair){
        var exclude = false;
        for ( var i in result["success"] ) {
          if ( pair[0] == i || util.PathUtils.isChild( pair[0], i ) ) {
            exclude = true;
            break;
          }
        }
        if (!exclude)  {
          newSelection.set( pair[0], pair[1] );
        } else {
          toggled.push( pair[1] );
        }
      });
      self.selections = newSelection;
      
      // 削除された親のディレクトリ一覧を取得
      var parents = $H({});
      for ( var i in result["success"] ) {
        var p = util.PathUtils.dirname( i );
        if (p) parents.set( p, p );
      }
      self.listeners.fire( self.EVENTS.CHANGED, {paths:parents.keys()}, "onAgentChanged" );
      self.listeners.fire( self.EVENTS.SELECTION_CHANGED, 
          {selection:self.selections, toggled:toggled}, "onAgentSelectionChanged" );
      
    }, function( error, detail ) {
      if ( fail) fail( {msg:util.BasicExceptionHandler( error, detail, 
          {name:fx.template.Templates.common.item.file} )} );
    });
  },
  /**
   * 選択されたファイル/フォルダをリネームする。(1つのファイル/フォルダのみリネーム可)
   * @param name {String} 新しい名前
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  renameSelection : function( name, success, fail ) {
    if ( !this.enable("renameSelection") ) {
      if ( fail) fail( {msg:fx.template.Templates.common.errorMsg.systemError} );
      return;
    }
    var path = this.selections.keys()[0];
    try {
      name = this.checkName( name, util.PathUtils.dirname(path), 
          this.selections.get( path ).type != "directory"  );
    } catch ( ex ) {
      if ( fail) fail( ex );
      return;
    }
    var self = this;
    var item = this.selections.get( path );
    this.agentServiceStub.rename( path, name, function( result) {
      if (success) success(result);
      
      // 成功した場合、選択されたアイテムの名前も変更
      // 選択は1つなので子が選択されていることはないはず。
      var item = self.selections.get(path);
      item.path = util.PathUtils.dirname(path) + "/" + name;
      item.name = name;
      self.selections.unset( path );
      self.selections.set( item.path, item );
      self.listeners.fire( self.EVENTS.CHANGED, {paths:[util.PathUtils.dirname( path )]}, "onAgentChanged" );
      self.listeners.fire( self.EVENTS.SELECTION_CHANGED, 
          {selection:self.selections, toggled:[item]}, "onAgentSelectionChanged" );
    }, function( error, detail ) {
      if ( fail) fail( {msg:util.BasicExceptionHandler( error, detail, 
          {name: item.type == "directory" 
              ? fx.template.Templates.common.item.directory
               : fx.template.Templates.common.item.file} )} );
    });
  },
  /**
   * 選択されたファイル/フォルダを移動する。
   * @param success {Function} 成功時のコールバック
   * @param fail {Function} 失敗時のコールバック
   */
  moveSelections : function( to, success, fail ) {
    if ( !this.enable("moveSelections") ) {
      if ( fail) fail( {msg:fx.template.Templates.common.errorMsg.systemError} );
      return;
    }
    if ( to.type != "directory") {
      if ( fail) fail( {msg:fx.template.Templates.common.errorMsg.systemError} );
      return;
    }
    var targets = this.selections.keys();
    this.agentServiceStub.move( targets, to.path, function(result){
      if (success) success(result);
      var changed = [to];
      // 移動前の親のディレクトリ一覧を取得
      var parents = $H({});
      for ( var i in result["success"] ) {
        var p = util.PathUtils.dirname( i );
        if (p) parents.set( p, p );
        // 移動された文書orその配下要素の選択を更新
        var newSelection = $H({});
        self.selections.each(function(pair){
          if (pair[0] == i || util.PathUtils.isChild( pair[0], i )) {
            var tmp = to + "/" + util.PathUtils.basename(i);
            pair[1].path = pair[0].path.sub( i, tmp );
            newSelection.set( pair[1].path, pair[1] );
          } else {
            newSelection.set( pair[1].path, pair[1] );
          }
        });
        self.selections = newSelection;
      }
      self.listeners.fire( self.EVENTS.CHANGED, {paths:parents.keys()}, "onAgentChanged" );
      self.listeners.fire( self.EVENTS.SELECTION_CHANGED, 
          {selection:self.selections},  "onAgentSelectionChanged" );
    }, function( error, detail ) {
      if ( fail) fail( {msg:util.BasicExceptionHandler( error, detail, 
          {name:fx.template.Templates.common.item.file} )} );
    });
  },
  /**
   * パスのファイル/フォルダを選択する
   * @param item {String} アイテム
   */
  select : function( item ) {
    this.selections.set(item.path, item);
    this.listeners.fire( this.EVENTS.SELECTION_CHANGED, 
        {selection:this.selections,toggled:[item]}, "onAgentSelectionChanged" );
  },
  /**
   * パスのファイル/フォルダを選択解除する
   * @param item {String} アイテム
   */
  unselect : function( item ) {
    this.selections.unset(item.path);
    this.listeners.fire( this.EVENTS.SELECTION_CHANGED, 
        {selection:this.selections,toggled:[item]}, "onAgentSelectionChanged" );
  },
  /**
   * パスのファイルが選択されているか評価する。
   * @param path {String} パス
   */
  isSelected : function( path ) {
    return this.selections.get(path) ? true : false;
  },
  /**
   * 選択された項目の数を返す。
   * @return 選択された項目数
   */
  size : function() {
    return this.selections.size();
  },
  /**
   * 選択を解除する。
   */
  clear : function() {
    var toggled = this.selections.values();
    this.selections = new Hash({});
    this.listeners.fire( this.EVENTS.SELECTION_CHANGED, 
        {selection:this.selections,toggled:toggled}, "onAgentSelectionChanged" );
  },
  /**
   * 選択されているあアイテムの一覧を返す。
   * @return 選択されているあアイテムの一覧
   */
  getSelections : function() {
    return this.selections.values();
  },
  /**
   * コマンドが利用可能か評価する
   * @param functionName {String} 関数名
   */
  enable : function( functionName ) {
    // moveSelections, removeSelectionsは選択がなければ実行不可
    switch( functionName ) {
      case "moveSelections":
      case "removeSelections":
        if (this.selections.size() <= 0) return false;
        if ( this.isSelected( fx.constants.AGENTS_DIR )  ) return false;
        if ( this.isSelected( fx.constants.SHARED_LIB_DIR )  ) return false;
        break;
      // renameSelectionは何かが一つ選択されていなければ実行不可
      case "renameSelection":
        if (this.selections.size() != 1) return false;
        if ( this.isSelected( fx.constants.AGENTS_DIR )  ) return false;
        if ( this.isSelected( fx.constants.SHARED_LIB_DIR )  ) return false;
        break;
      // add,mkcolはフォルダが1つ選択されていなければ実行不可
      case "add":
      case "mkcol":
        if (this.selections.size() != 1) return false;
        if ( this.selections.values()[0].type != "directory") return false;
        break;
    }
    return true;
  },
  /**
   * ファイル名/フォルダ名が利用可能であるか評価する
   * @param name {String} 名前
   * @param parent {String} 親のパス名
   * @param isFile {Boolean} ファイルかどうか?
   * @return パス
   */
  checkName : function( name, parent, isFile ){
    var option = { name: isFile 
      ? fx.template.Templates.common.item.file
      : fx.template.Templates.common.item.directory };
  
    // 文字列をチェック
    if ( !name ) {
      throw {msg:fx.template.Templates.common.errorMsg.emptyName};
    }
    if ( !name.match( /^[A-Za-z0-9_\+\-\#\'\!\~\(\)\[\]\.\{\}]+$/ ) ) {
      throw {msg:fx.template.Templates.common.errorMsg.illegalName.evaluate( option )};
    }

    // ファイルの場合、拡張子を強制的に付与する
    if ( isFile && !name.match( /\.rb$/ ) ) {
        name += ".rb";
    }
    return name;
  }
}