package fx.chart.ui.graph {

  import fx.util.*;
  import fx.chart.ui.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;
  import flash.display.*;
  import flash.text.*;
  import flash.geom.*;
  import flash.external.*;
  
  /**
   * グラフマネージャ
   */
  public class GraphManager extends AbstractDrawChartUI {

     /**
      * グラフ情報のマップ
      */
    private var infos:Object = {};

    public function GraphManager( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );
      
      // 一覧UIを描く
    }

    /**
     * グラフ一覧が更新された場合に呼び出される。
     * swfの初期化時やpidが更新された場合に発生。
     */
    public function onGraphListChanged(ev:*):void {

        // 既存のグラフは一旦破棄
        for ( var i:* in infos ) {
          for ( var j:* in infos[i] ) {
            if ( infos[i][j].graph ) {
              infos[i][j].graph.destroy();
            }
          }
        }
        infos = {};

        // グラフ一覧を作成
        for ( var graph:* in model.graphs ) {
            infos[graph] = {};
            var x:* = model.graphs[graph]["outputs"];
            x ||= {};
            for ( var g:* in x ) {
              infos[graph][g] = new GraphInfo( x[g], null,  model, ctrl, rc );
            }
        }

        // グラフデータを取得して描画。
        updateGraphs();
    }

    /**
     * ローソク足データが更新された場合に呼び出される。
     */
    public function onCandleDataChanged(ev:Event):void {
        // グラフデータを再取得&&更新
        updateGraphs();
    }

    public function on( name:Array ):void {
      // レイヤーを非表示。
      if ( infos && infos[name[0]] && infos[name[0]][name[1]]  ) {
        var target:GraphInfo = infos[name[0]][name[1]];
        target.visible = true;
        
        // データが未取得であればとってくる。
        if ( !target.datas ) {
          ctrl.requestOutputDatas( [name], function( map:Object ):void {
            target.datas = null;
            if ( map[name[0]][name[1]] ) {
              target.datas = map[name[0]][name[1]];
              // グラフ表示
              target.draw( );
              target.graph.setVisible(true);
            }
          });
        } else {
          // 取得済みであればレイヤーを表示するだけ。
          target.graph.setVisible(true);
          target.draw();
        }
      }
    }
    public function off( name:Array ):void {
      // レイヤーを非表示。
      if ( infos && infos[name[0]] && infos[name[0]][name[1]]  ) {
        var target:GraphInfo = infos[name[0]][name[1]];
        target.visible = false;
        target.graph.setVisible(false);
        target.draw();
      }
    }
    /**
     * グラフの色を更新する
     */
    public function setGraphColors( name:Array, colors:Array ):void {
        // レイヤーを非表示。
        if ( infos && infos[name[0]] && infos[name[0]][name[1]]  ) {
            var target:GraphInfo = infos[name[0]][name[1]];
            target.setColors( colors ); 
            target.draw(); // グラフを再描画
        }
    }
    
    /**
     * グラフを削除する
     */
    public function removeGraph( agentId:String ):void {
        // レイヤーを非表示。
        if ( infos && infos[agentId]  ) {
            for ( var j:* in infos[agentId] ) {
              off( [agentId, j] );
            }
        }
    }
    
    /**
     * グラフデータを再取得して更新する。
     */
    public function updateGraphs():void {
        var names:Array = [];
        for ( var i:* in infos ) {
          for ( var j:* in infos[i] ) {
              infos[i][j].datas = null;
              if ( infos[i][j].visible ) {
                names.push( [i,j] );
              }
          }
        }
        if ( names.length <= 0 ) { return; }
        ctrl.requestOutputDatas( names, function( map:Object ):void {
          names.forEach( function( item:*,i:int,arr:Array ):void {
              if ( map[item[0]] && map[item[0]][item[1]] ) {
                  infos[item[0]][item[1]].datas = map[item[0]][item[1]] ;
                  // グラフ表示
                  if ( infos[item[0]][item[1]].visible ) { 
                    infos[item[0]][item[1]].draw( );
                  }
              }
          } );
        });
    }
  }
}

import fx.chart.ui.*;
import fx.chart.model.*;
import fx.chart.ctrl.*;
import fx.chart.ui.graph.Graph;

class GraphInfo {
    
  internal  var info:Object;
  internal  var visible:Boolean;
  internal  var datas:Array;
  internal  var colors:Array;
  internal  var graph:Graph;

  function GraphInfo( info:Object, datas:Array,
    model:Model, controller:Controller, rc:RenderingContext ) {
    this.info = info;
    this.visible = info["visible"] == false ? false : true;
    this.datas = datas;
    if ( info["colors"] && info["colors"] is Array ) {
      setColors( info["colors"] ); 
    }
    this.graph = new Graph( model, controller, rc );
  }
  internal function draw():void {
    graph.draw( {
      "datas": datas,
      "options": info
    }, colors );
  }
  internal function setColors( colors:Array):void {
      var self:GraphInfo = this;
      self.colors = [];
      colors.forEach( function(c:*,i:int,arr:Array):void {
        if ( c is String && c.match(/\#([a-fA-F0-9]{6})/) ) {
          self.colors.push( Number(c.replace(/^\#/, "0x")));
        }
      });
  }
}

