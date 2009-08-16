// ネームスペース
namespace( "fx.ui" )
namespace( "fx.ui.pages" )

// エージェント追加/編集UI
fx.ui.pages.AgentEditorPage = function() {
  this.elementId = null;
  this.editorElementId = null;
  this.agentEditor = container.Inject;
  this.agentFileListTree = container.Inject;
  this.dialog = container.Inject;
  this.topicPath = container.Inject;

  // ボタン
  var self = this;
  this.addButton = new util.Button("agent-edit_add", "add_small", function() {
    self.add("file");
  }, fx.template.Templates.common.button.fileAdd);
  this.addButton.setEnable( false );

  this.removeButton = new util.Button("agent-edit_remove", "remove_small", function() {
    self.remove();
  }, fx.template.Templates.common.button.del);
  this.removeButton.setEnable( false );

  this.mkcolButton = new util.Button("agent-edit_mkcol", "mkcol", function() {
    self.add("directory");
  }, fx.template.Templates.common.button.mkcol);
  this.mkcolButton.setEnable( false );
  
  this.renameButton = new util.Button("agent-edit_rename", "rename", function() {
    self.add("rename");
  }, fx.template.Templates.common.button.rename);
  this.renameButton.setEnable( false );
}
fx.ui.pages.AgentEditorPage.prototype = {

  /**
   * このページから画面を移動する際に呼び出される。
   * 戻り値としてfalseを返すと遷移をキャンセルする。
   */
  from : function(toId) {
    // ページを非表示
    document.getElementById(this.elementId).style.display = "none";
    this.topicPath.set("");
    return true;
  },
  /**
   * このページに画面を移動すると呼び出される。
   */
  to : function( fromId, param ) {
    // ページを表示
    document.getElementById(this.elementId).style.display = "block";
    this.topicPath.set( fx.template.Templates.agentEditor.topicPath );
    document.getElementById("agent_edit_desc").innerHTML =
      fx.template.Templates.agentEditor.desc
    this.initialize();
  },

  initialize: function( ) {
    var self = this;
    if ( this.initializeed ) return;
    
    this.agentFileListTree.init();

    // ファイルのダブルクリックで編集開始
    this.agentFileListTree.tree.subscribe( "dblClickEvent", function(ev, node) {
      self.startEdit( ev.node.data.data );
    } );

    // 編集領域を初期化
    editAreaLoader.init({
      id : this.editorElementId,
      syntax: "ruby",
      start_highlight: true,
      language: "ja",
      allow_toggle: false,
      allow_resize: "y",
      font_size: 10,
      toolbar: "save, |, search, go_to_line, fullscreen, |, undo, redo, |, select_font,|, help ",
      is_multi_files: true,
      save_callback: "fx.ui.pages.AgentEditorPage.EditAreaCallBacks.saved",
      EA_file_close_callback: "fx.ui.pages.AgentEditorPage.EditAreaCallBacks.closed"
    });

    // コールバック関数
    fx.ui.pages.AgentEditorPage.EditAreaCallBacks = {
      // データが保存されると呼び出されるコールバック関数
      saved : function(  editor_id, content ) {
         var file = editAreaLoader.getCurrentFile(editor_id);
         var editorPage = fx.ui.pages.AgentEditorPage.EditAreaCallBacks.findEditorPage();
         editorPage.save( {path:file.id,name:file.name,type:"file"}, file.text);  
         // 保存に成功したら、編集状態を解除(タイトルの「*」を消す)
         editAreaLoader.setFileEditedMode(editor_id, file.id, false);
      },
      // タブがクローズされると呼び出されるコールバック関数。
      closed : function(file) {
        // 未保存であれば保存を確認
        if (!file['edited']) return true;
        fx.container.get("dialog").show( "input", {
          message : fx.template.Templates.agentEditor.dosave,
          buttons : [
            { type:"yes",
              alt: fx.template.Templates.common.button.yes,
              key: "Enter",
              action: function(dialog){
                var editorPage = fx.ui.pages.AgentEditorPage.EditAreaCallBacks.findEditorPage();
                editorPage.save( {path:file.id,name:file.name,type:"file"}, file.text);  
                return true;
            }},
            { type:"no",
              alt: fx.template.Templates.common.button.no,
              key: "Esc",
              action: function(dialog){ return true;}
            }
          ]
        });
        return true;
      },
      findEditorPage : function() {
        var pages = fx.container.gets("pages");
        for ( var i=0; i<pages.length;i++ ) {
          if ( pages[i].id != "agent_edit" ) continue;
          return pages[i];
        }
      }
    }
    this.initializeed = true;
  },

  // エージェントの選択が更新された
  onAgentSelectionChanged : function(ev) {
    // ボタンのグレーアウト更新
    this.addButton.setEnable( this.agentEditor.enable("add") );
    this.removeButton.setEnable( this.agentEditor.enable("removeSelections") );
    this.mkcolButton.setEnable( this.agentEditor.enable("mkcol") );
    this.renameButton.setEnable( this.agentEditor.enable("renameSelection") );
    
    // 表示を更新
    var self = this;
    ev.toggled.each( function(item) {
      var node = self.agentFileListTree.tree.getNodeByProperty( "path", item.path );
      // データがリロードされている場合、IDが変わるので、引数のitemで保持されているIDはそのまま利用できない。
      if (!node) return;
      var elm = document.getElementById( "agent_tree_node_" + node.data.data.id );
      if ( Element.hasClassName(elm, "selected") ) {
        Element.removeClassName(elm, "selected");
      } else {
        Element.addClassName(elm, "selected");
      }
    });
  },

  // エージェントが更新された
  onAgentChanged : function(ev) {
    for ( var i=0,n=ev.paths.length;i<n;i++ ) {
      this.agentFileListTree.updateNode( ev.paths[i] );
    }
  },
  
  // エディタを利用不可にする。
  disableEditor : function() {
    editAreaLoader.hide(this.editorElementId)
  },
  // エディタを利用可にする。
  enableEditor : function() {
    editAreaLoader.show(this.editorElementId)
  },
  // 追加/リネーム
  add: function( mode ){
    // ダイアログを開く
    var self = this;
    var option = { text:""};
    switch ( mode ) {
      case "directory" : 
        option.type = fx.template.Templates.common.item.directory;
        option.prefix = fx.template.Templates.agentEditor.add.prefix.add;
        break;
      case "file" :         
        option.type = fx.template.Templates.common.item.file;
        option.prefix = fx.template.Templates.agentEditor.add.prefix.add;
        break;
      default :
        var selected = this.agentEditor.getSelections()[0];
        option.text = selected.name;
        option.type = selected.type == "directory" 
          ? fx.template.Templates.common.item.directory 
          : fx.template.Templates.common.item.file;
        option.prefix = fx.template.Templates.agentEditor.add.prefix.rename;
        break;
    }
    this.dialog.show( "input", {
      message : fx.template.Templates.agentEditor.add.body.evaluate(option),
      init: function() {
        document.file_name_input_form.file_name_input.focus();
        self.disableEditor();
      },
      buttons : [
        { type:"ok",
          alt: fx.template.Templates.common.button.ok,
          key: "Enter",
          action: function(dialog){
            var text = document.getElementById("file_name_input").value;
            try {
              JSONBrokerClientFactory.async = false;
              var result = true;
              var f = "renameSelection";
              switch ( mode ) {
                case "directory" : f = "mkcol"; break;
                case "file" : f = "add"; break;
                default : f = "renameSelection"; break;
              }
              self.agentEditor[f]( text, function(){}, function(ex){
                // エラー通知
                dialog.content.innerHTML =
                  fx.template.Templates.agentEditor.add.error.evaluate({ "error" : ex.msg.escapeHTML() })
                  + fx.template.Templates.agentEditor.add.body.evaluate({ "text" : text.escapeHTML() })
                result = false;
              });
              return result;
            } finally {
              JSONBrokerClientFactory.async = true;
              self.enableEditor();
            }
            return true;
        }},
        { type:"cancel",
          alt: fx.template.Templates.common.button.cancel,
          key: "Esc",
          action: function(dialog){
            self.enableEditor();
            return true;
        }}
      ]
    } );
  },
  // 削除
  remove: function(){
    // 確認
    var self = this;
    this.dialog.show( "input", {
      message : fx.template.Templates.agentEditor.remove.body,
      init: function() { self.disableEditor(); },
      buttons : [
        { type:"ok",
          alt: fx.template.Templates.common.button.ok,
          key: "Enter",
          action: function(dialog){
            try {
              // 行のデータを削除
              self.agentEditor.removeSelections( function(result){
                var str = "";
                for ( var i in result.failed ) {
                  str += result.failed[i].path + " : \n    " +  result.failed[i].msg;
                }
                if ( str.length > 0 ) {
                  var body = fx.template.Templates.agentEditor.remove.error.evaluate( {error:str} );
                  self.showError( body );
                }
              }, function(ex) {
                var body = fx.template.Templates.agentEditor.remove.error.evaluate( {error:ex.msg} );
                self.showError( body );
              } );
            } finally {
              self.enableEditor();
            }
            return true;
          }
        },
        { type:"cancel",
          alt: fx.template.Templates.common.button.cancel,
          key: "Esc",
          action: function(dialog){
            self.enableEditor();
            return true;
          }
        }
      ]
    });
  },
  // エラーを表示する。
  showError : function( msg ) {
    // 確認
    var self = this;
    this.dialog.show( "warn", {
      message : msg,
      init: function() { self.enableEditor(); },
      buttons : [
        { type:"ok",
          alt: fx.template.Templates.common.button.ok,
          key: "Enter",
          action: function(dialog){
            self.enableEditor();
            return true;
          }
        }
      ]
    });
  },
  
  // データを保存する。
  save: function( editingFile, newData ){
    var self = this;
    this.agentEditor.put( editingFile.path, newData, function(result){
      document.getElementById("agent_edit_msg").innerHTML =
        fx.template.Templates.agentEditor.saved.success.evaluate({ "now" : util.formatDate( new Date() ) });
    }, function(result, detail) {
      document.getElementById("agent_edit_msg").innerHTML =
        fx.template.Templates.agentEditor.saved.error.evaluate({ "now" : util.formatDate( new Date() ), "result":result.escapeHTML()} );
    } );
  },

  // 編集を開始する。
  startEdit : function( file ) {
    var self = this;
    this.agentEditor.get( file.path, function(body) {
      editAreaLoader.openFile(self.editorElementId, {
        id : file.path,
        title : file.name,
        text : body
      });
    }, function(){}); // TODO
  }
}