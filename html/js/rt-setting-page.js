
// ネームスペース
namespace( "fx.ui.pages" )

// バックテスト新規作成
fx.ui.pages.RtSettingPage = function() {
  this.elementId = null // @Inject
  this.processServiceStub = container.Inject;

  this.agentSelector = container.Inject("rtSettingAgentSelector");
  this.dialog = container.Inject;
  this.topicPath = container.Inject;
  this.tradeEnable = container.Inject;

  // ボタン
  var self = this;
  this.applyButton = new util.Button("rt-setting__ok", "apply", function() {
    self.ok();
  }, fx.template.Templates.common.button.apply);
  this.applyButton.setEnable( true );
}
fx.ui.pages.RtSettingPage.prototype = {

  /**
   * このページから画面を移動する際に呼び出される。
   * 戻り値としてfalseを返すと遷移をキャンセルする。
   */
  from : function(toId) {
    // ページを非表示
    document.getElementById(this.elementId).style.display = "none";
    this.topicPath.set( "" );
    return true;
  },
  /**
   * このページに画面を移動すると呼び出される。
   */
  to : function( fromId ) {
    // ページを表示
    document.getElementById(this.elementId).style.display = "block";

    var msg = document.getElementById("rt-setting_msg");
    msg.innerHTML = "";
    msg.style.display = "none";

    this.topicPath.set( fx.template.Templates.rtsetting.topicPath );

    // 既存の設定情報を取得
    this.reloadAgents();
  },
  initialize: function( ) {
    this.agentSelector.initialize();
  },
  reloadAgents : function() {
    var self = this;
    this.getSetting( function( data ) {
      document.getElementById("rt-setting_trade-enable").checked =
        (data["trade_enable"] == true );
      self.agentSelector.setAgents( data["agents"] );
    }, null ); // TODO
  },

  ok: function(){

    // エラーチェック
    if ( this.agentSelector.hasError() ) {
      this.dialog.show( "warn", {
        message : fx.template.Templates.common.errorMsg.illegalAgentSetting,
        buttons : [
          { type:"ok", alt: fx.template.Templates.common.button.ok, key: "Enter" }
        ]
      } );
      return;
    }
    var agents = this.agentSelector.getAgents();

    // ダイアログを開く
    var self = this;
    this.dialog.show( "input", {
      message : fx.template.Templates.rtsetting.apply.msg,
      buttons : [
        { type:"ok",
          alt: fx.template.Templates.common.button.ok,
          key: "Enter",
          action: function(dialog){
          var enable = document.getElementById("rt-setting_trade-enable").checked;
          self.updateSetting( enable, agents, function(result) {

            // 失敗した操作があればメッセージを表示
            var error = "";
            for ( var i in result ) {
              var operation = fx.template.Templates.rtsetting.update.op.remove;
              switch (result[i]["operation"]) {
                case "add" : operation = fx.template.Templates.rtsetting.update.op.add; break;
                case "update" : operation = fx.template.Templates.rtsetting.update.op.update; break;
              }
              error += fx.template.Templates.rtsetting.update.errorDetail.evaluate({
                "operation": operation,
                "name" : result[i]["info"]["name"],
                "cause" : result[i]["cause"]
              });
            }
            if ( error ) {
	            self.dialog.show( "warn", {
	              message : fx.template.Templates.rtsetting.update.error.evaluate({
	                "error":error.escapeHTML()})
	            });
            }

            // 更新時刻を表示
            var dateStr = util.formatDate( new Date() );
            var msg = document.getElementById("rt-setting_msg");
            msg.innerHTML =fx.template.Templates.rtsetting.apply.success.evaluate( {dateStr:dateStr} );
            msg.style.display = "block";

            // 自動更新設定を更新
            self.tradeEnable.set( enable );

          }, function(error, detail){
            self.dialog.show( "warn", {
              message : fx.template.Templates.rtsetting.apply.error.evaluate({
                "error":(String(error) + "\n" + String(detail["backtrace"])).escapeHTML()})
            });
          });
        } },
        { type:"cancel", alt: fx.template.Templates.common.button.cancel, key: "Esc" }
      ]
    } );
  },

  /**
   * 設定値を取得する。
   * @param {Function} success 成功時のコールバック
   * @param {Function} fail 失敗時のコールバック
   */
  getSetting : function( success, fail ) {
    this.processServiceStub.get( "rmt", success, fail );
  },

  /**
   * 設定値を反映する
   * @param {Boolean} tradeEnable 取引を行なうか
   * @param {Object} agents エージェントとプロパティ一覧
   * @param {Function} success 成功時のコールバック
   * @param {Function} fail 失敗時のコールバック
   */
  updateSetting : function( tradeEnable, agents, success, fail ) {
    this.processServiceStub.set( "rmt", {
      "trade_enable": tradeEnable,
      "agents": agents
    }, success, fail );
  }
}
