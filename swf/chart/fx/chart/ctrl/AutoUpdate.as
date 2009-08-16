package fx.chart.ctrl {

  import fx.chart.*;
  import fx.chart.model.*;
  import fx.net.*;
  import fx.util.*;
  import flash.utils.Timer;
  import flash.events.TimerEvent;
  
  /**
   * 自動更新
   */
  public class AutoUpdate {

    /**
     * タイマー。未起動の場合null
     */
    private var timer:Timer;

    /**
     * 自動更新を有効化するかどうか
     */
    private var enable:Boolean;

    /**
     * モデル
     */
    private var model:Model;

    /**
     * コントローラー
     */
    private var ctrl:Controller;

    public function AutoUpdate( model:Model,
        controller:Controller ) {
        this.model = model;
        this.ctrl = controller;
    }

    /**
     * 自動更新を開始する。
     */
    public function start():void {
        
      // タイマーを作成。
      timer = new Timer(model.scaleTime*1000, 0);

      // チャートを更新。
      timer.addEventListener("timer", function(ev:TimerEvent):void {
          ctrl.init( model.processId, model.pair, model.scale, null );
      });
      // タイマーを開始
      timer.start();
    }

    /**
     * 自動更新を停止する。
     */
    public function stop():void  {
      if ( timer ) {
        timer.stop();
        timer = null;
      }
    }

    /**
     * スケールが変更された
     */
    public function onScaleChanged( ev:Event ):void {
      // タイマーを再起動
      stop();
      start();
    }

    /**
     * 日時の範囲が更新された
     */
    public function onRangeChanged( ev:Event ):void {
        // 自動更新フラグが立っていれば日付を再設定
        // 最新のデータが表示されるようにマージンを取る
        if ( enable ) {
          ctrl.changeDate(
            Util.createDate( model.range.last * 1000 - model.scaleTime * 25 ) );
        }
    }

    /**
     * 自動更新を行なうかどうか。
     */
    public function setEnable( enable:Boolean ):void {
      this.enable = enable;
    }

  }
}
