
// ネームスペース
namespace( "fx" );


// 定数
fx.constants = {
  SERVICE_URI : "./json",
  AGENTS_DIR : "agents",
  SHARED_LIB_DIR : "shared_lib"
}

// モジュール
fx.modules = {
  // UIモジュール
  ui : function(binder) {
    // App
    binder.bind( fx.Application ).to( "app" );

    // page manager
    binder.bind( util.PageManager ).to( "pageManager" ).initialize( function( obj, container ) {
        obj.init( container.gets("pages"));
    });

    // pages
    binder.bind( fx.ui.pages.RtSettingPage ).to( "pages" ).inject({
      id : "rt_setting",
      elementId : "page-rt-setting"
    }).initialize("initialize");
    binder.bind( fx.ui.pages.AgentEditorPage ).to( "pages" ).inject({
      id : "agent_edit",
      elementId : "page-agent-edit",
      editorElementId : "agent_editor"
    });
    binder.bind( fx.ui.pages.BtCreatePage ).to( "pages" ).inject({
      id : "bt_create",
      elementId : "page-bt-create"
    }).initialize("initialize");
    binder.bind( fx.ui.pages.ResultPage ).to( "pages" ).inject({
      id : "result",
      elementId : "page-result"
    }).initialize("initialize");

    // page manager (結果一覧ページ用)
    binder.bind( util.PageManager ).to( "resultPageManager" ).initialize( function( obj, container ) {
        obj.init( container.gets("result_pages"));
    });
    binder.bind( fx.ui.pages.LogResultPage ).to( "result_pages" ).inject({
      id : "log",
      elementId : "subpage-log"
    });
    binder.bind( fx.ui.pages.TradeResultPage ).to( "result_pages" ).inject({
      id : "trade",
      elementId : "subpage-trade"
    });
    binder.bind( fx.ui.pages.InfoResultPage ).to( "result_pages" ).inject({
      id : "info",
      elementId : "subpage-info"
    }).initialize("initialize");
    binder.bind( fx.ui.pages.GraphSettingResultPage ).to( "result_pages" ).inject({
      id : "graph",
      elementId : "subpage-graph"
    });

    // agent editor
    binder.bind( fx.agent.ui.AgentSelector ).to( "rtSettingAgentSelector" ).inject({
      id: "rt-setting_as"
    });
    binder.bind( fx.agent.ui.AgentSelector ).to( "btCreateAgentSelector" ).inject({
      id: "bt-create_as"
    });
    binder.bind( fx.agent.ui.AgentSelector ).to( "subpageInfoAgentSelector" ).inject({
      id: "subpage-info_as"
    });

    // agent-edit
    binder.bind( fx.ui.AgentFileListTree ).to( "agentFileListTree" ).inject({
      elementId : "agent-file-list"
    });

    // side-bar
    binder.bind( fx.ui.SideBar ).to( "sideBar" ).inject({
      elementId : "back-tests"
    });

    // topicPath
    binder.bind( util.TopicPath ).to( "topicPath" ).inject({
      elementId : "topic_path"
    });

    // tradeEnable
    binder.bind( fx.ui.TradeEnable ).to( "tradeEnable" ).inject({
      elementId : "head_trade_enable"
    }).initialize("init");

    // dialog
    binder.bind( util.Dialog ).to( "dialog" );
  },

  // 非UI
  core : function( binder ) {

    // ctrl
    binder.bind( fx.AgentEditor ).to( "agentEditor" ).initialize("init");

    // stub
    binder.bindProvider( function() {
      return JSONBrokerClientFactory.createFromList(
        fx.constants.SERVICE_URI + "/agent",
        ["list_agent_class",
         "put_file", "add_file", "mkcol",
         "remove",
         "move", "rename",
         "list_agent",
         "add_agent",
         "remove_agent",
         "off", "on",
         "list_files",
         "get_file"] );
    } ).to("agentServiceStub");

    binder.bindProvider( function() {
      return JSONBrokerClientFactory.createFromList(
        fx.constants.SERVICE_URI + "/process",
        ["list_test",
         "get",
         "set",
         "new_test",
         "status",
         "delete_test",
         "stop",
         "restart"] );
    } ).to("processServiceStub");
    binder.bindProvider( function() {
      return JSONBrokerClientFactory.createFromList(
        fx.constants.SERVICE_URI + "/output",
        [ "get_log", "list_outputs", "set_properties", "delete_output" ] );
    } ).to("outputServiceStub");
    binder.bindProvider( function() {
      return JSONBrokerClientFactory.createFromList(
        fx.constants.SERVICE_URI + "/trade_result",
        [ "list" ] );
    } ).to("tradeResultServiceStub");
    binder.bindProvider( function() {
      return JSONBrokerClientFactory.createFromList(
        fx.constants.SERVICE_URI + "/rate",
        [ "range" ] );
    } ).to("rateServiceStub");
  }
}

fx.initialize = function(){
  fx.container = new container.Container( function( binder ){
    fx.modules.ui( binder );
    fx.modules.core( binder );
  });
  fx.app = fx.container.get( "app" );
  fx.app.initialize();
}


fx.Application = function() {
  this.pageManager = container.Inject;
  this.sideBar = container.Inject;
}
fx.Application.prototype = {

  /**
   * 初期化
   */
  initialize : function (  ) {
    var self = this;
    this.sideBar.initialize();
    this.sideBar.to("sidebar_result_rmt");
  },

  /**
   * エラーがあれば表示する。
   * @param {Object} arg1 パラメータ
   * @param {Object} arg2 パラメータ
   */
  showError: function(arg1, arg2){
  	alert("error:" + arg1 + " " +arg2 );
  }
}

function debug(obj) {
  var out = document.getElementById('debug');
  if ( typeof obj == "string" ) {
    out.innerHTML += obj + "<br/>";
  } else {
    out.innerHTML += "---<br/>";
    out.innerHTML += obj + "<br/>";
    for ( var i in obj ) {
      out.innerHTML += i + " : " + obj[i] + "<br/>";
    }
  }
}
