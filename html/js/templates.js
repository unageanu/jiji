
// ネームスペース
namespace( "fx" );
namespace( "fx.template" );
fx.template.Templates = {
  common: {
    loading : '<img src="./img/loading.gif"  alt="loading.." title="loading.." />',
    date: {
      d:"日", m:"月", y:"年",
      h:"時間", mm: "分", s:"秒"
    },
    button : {
      start: "開始",
      apply  : "適用",
      update : "更新",
      add : "追加",
      del : "削除",
      fileAdd : "ファイルを追加",
      mkcol : "ディレクトリを追加",
      rename : "選択したファイル/ディレクトリの名前を変更",
      save : "保存",
      ok  : "OK",
      cancel: "キャンセル",
      yes  : "はい",
      no: "いいえ"
    },
    column : {
      name : "名前",
      update : "最終更新日時",
      profitOrLoss : "損益",
      swap : "スワップ",
      sellOrBuy : "売/買",
      state : "状態",
      pair : "通貨ペア",
      rate : "レート",
      fixRate : "決済レート",
      count : "数量",
      trader : "エージェント",
      date : "取引日時",
      fixDate : "決済日時",
      totalProfitOrLoss: "損益合計",
      totalSwap : "累計スワップ",
      tradeSummary : "取引回数/約定済み",
      winRate : "勝率",
      maxProfit: "最大利益",
      maxLoss: "最大損失",
      avgProfitOrLoss:"平均損益",
      profitRatio:"損益率"
    },
    sell : "売",
    buy : "買",
    positionState : {
      order: "注文中",
      having: "所有中",
      settle: "決済注文中",
      settled: "決済済",
      lost: "ロスト",
      unknown: "不明"
    },
    item : {
      file: "ファイル",
      directory: "ディレクトリ"
    },
    errorMsg : {
      notFound: new Template("#{name}が見つかりませんでしました。"),
      alreadyExist: "名前が重複しています。",
      isNotFile: "ファイルではありません",
      isNotFolder: "フォルダではありません",
      illegalName: new Template("#{name}名が不正です。半角英数字、および「_+-#!~[]().'{}」のみ使用可能です。"),

      systemError : "内部エラーが発生しました。",
      serverError : "サーバーでエラーが発生しました。",
      notSelected : "エージェントが選択されていません。",
      deleteConfirm:"削除します。よろしいですか?",
      selectAgent : "エージェントを選択してください。",
      notInput : "値が入力されていません。",
      notNumber : "数値を入力してください。",
      outOfRange : "値が範囲外です。",
      tooLong : "値が長すぎます。",
      illegalChar:"使用できない文字が含まれています。",
      illegalFormat : "値のフォーマットが不正です。",
      dupricateName : "名前が重複しています。",
      emptyName : "名前が入力されていません。",
      illegalAgentSetting: "エージェントの設定に問題があります。",
      illegalDate : "開始日または終了日が不正です。",
      illegalStartDate : "開始日が入力されていないか、フォーマットが不正です。",
      illegalEndDate : "終了日が入力されていないか、フォーマットが不正です。"
    }
  },
  agentSelector: {
    defaultName : "名称未設定エージェント",
    error : new Template( '<div class="problem">※#{error}</div>#{msg}'),
    addMsg : "追加するエージェントを選択してください。"
      + '<div style="margin-top:10px;border: 1px solid #FFFFFF;">'
      + '  <div id="agent_class_list"></div>'
      + '</div>'
  },
  agentEditor: {
    topicPath: "エージェント:作成/編集",
    desc: "※エージェントまたは共有ライブラリを作成・編集します。ツリーからファイルをダブルクリックして編集して下さい。"
        + "エージェントの作り方は<a href='http://unageanu.sakura.ne.jp/jiji/?page=agent&param=a_agent_0' target='_blank'>こちら。</a><br/>"
        + "※改変後のコードは次にエージェントや共有ライブラリのAPIを使用した場合に有効になります。",
    saved : {
      error : new Template(
          '<span class="problem">※コンパイルエラー</span> <span style="color: #FF3366;">( #{now} ) <br/>' +
          ' #{result}</span>'),
      success : new Template('※保存しました。 ( #{now} )')
    },
    dosave : "未保存のデータがあります。保存しますか?",
    add : {
      prefix : {
        add : "追加する",
        rename : "新しい"
      },
      error : new Template(
        '<div class="problem">※#{error}</div>'
      ),
      body : new Template(
        "#{prefix}#{type}名を入力してください。<br/>" +
        '<form action="javascript:void(0);" name="file_name_input_form">' +
        '  <input id="file_name_input" name="file_name_input" type="text"' +
        '    style="width:360px;margin-top:10px;" value="#{text}" />'+
        '</form>')
    },
    remove: {
      body : "ファイルを削除します。削除したファイルは復元できません。<br/>よろしいですか?",
      error: new Template("<span class='problem'>※ファイルまたはフォルダの削除に失敗しました。" +
          "<pre style='width:350px;height:200px;overflow:scroll;font-size:11px;font-weight:normal'>#{error}</pre>" +
          "</span>")
    },
    defaultFileName: "( ファイルを選択してください。 )",
    tree : {
      node : new Template(
          '<div id="agent_tree_node_#{id}" class="node #{type} #{selected}">' +
          '  <span class="name">#{name}</span>'+
          '</div>')
    }
  },
  agentPropertyEditor: {
    none: new Template(
      'エージェントを選択してください。' ),
    selected: new Template(
      '<form id="agent-property-editor-form_#{id}" name="agent-property-editor-form_#{id}" action="javascript:return false;">' +
      '  <div class="item">'+
      '    <div class="title">名前</div>' +
      '    <div class="value"><input name="agent_name" id="agent_name" type="text" value="#{name}"/></div>'+
      '  <div class="property-problem" id="agent_name_problem"></div>' +
      '  </div>' +
      '  <div class="item">'+
      '    <div class="title">クラス</div>' +
      '    <div class="value">' +
      '     #{class_name}<pre>#{desc}</pre>'+
      '    </div>'+
      '  </div>' +
      '  <div class="item">'+
      '    <div class="title">プロパティ</div>' +
      '    <div class="value"><div class="property-container">' +
      '     #{properties}' +
      '    </div></div>'+
      '  </div>' +
      '</form>' ),
      selectedReadOnly: new Template(
          '  <div class="item">'+
          '    <div class="title">名前</div>' +
          '    <div class="value">#{name}</div>'+
          '  </div>' +
          '  <div class="item">'+
          '    <div class="title">クラス</div>' +
          '    <div class="value">' +
          '     #{class_name}<pre>#{desc}</pre>'+
          '    </div>'+
          '  </div>' +
          '  <div class="item">'+
          '    <div class="title">プロパティ</div>' +
          '    <div class="value"><div class="property-container">' +
          '     #{properties}' +
          '    </div></div>'+
          '  </div>'  ),
    property: new Template(
      '<div class="propery">'+
      '  <div class="property-description">#{name}</div>' +
      '  <input class="property-input" name="property_#{id}" id="property_#{id}"  type="text" value="#{default}" />'+
      '  <div class="property-problem" id="property_#{id}_problem"></div>' +
      '</div>' ),
    propertyReadOnly: new Template(
      '<div class="propery">'+
      '  <div class="property-description">#{name}</div>' +
      '  <div class="property-value">#{default} </div>'+
      '</div>' )
  },
  sidebar : {
    del : {
      msg : "バックテストを削除します。よろしいですか?"
    },
    processState : {
      waiting :  "待機中",
      running : "実行中",
      canceled : "中止",
      finished : "完了",
      errorEnd : "<span class='error'>エラー終了</span>"
    },
    process : new Template (
      '  <div class="name">' +
      '    <span id="process_#{id}_name">#{name}</span>' +
      '    <span class="process_restart">' +
      '<a href="javascript:fx.app.sideBar.restart(\'#{id}\');" id="process_#{id}_restart" style="display:none;padding-left:2px;" title="再実行" alt="再実行">' +
      '<img src="./img/control_play.png" title="再実行" alt="再実行" '  +
      '         onmouseover="this.src=\'./img/control_play_blue.png\'" '  +
      '         onmouseout="this.src=\'./img/control_play.png\'" />' +
      '</a>' +
      '</span>' +
      '<span class="process_delete">' +
      '<a href="javascript:fx.app.sideBar.remove(\'#{id}\');" id="process_#{id}_delete"  title="削除" alt="削除">' +
      '<img src="./img/bin_closed.png" title="削除" alt="削除"' +
      '         onmouseover="this.src=\'./img/bin_empty.png\'"'  +
      '         onmouseout="this.src=\'./img/bin_closed.png\'" />' +
      '</a>' +
      '</span>' +
      '  </div>' +
      '  <div class="detail">'+
      '    <div class="date">#{date}</div>' +
      '    <div class="state" id="process_#{id}_state">状態:#{state}</div>' +
      '    <div class="progress" id="process_#{id}_progress">' +
      '      <div class="progress_bar" id="process_#{id}_progress_bar"></div>' +
      '      <div class="progress_value" id="process_#{id}_progress_value"></div>' +
      '      <div class="breaker"></div>' +
      '    </div>' +
      '  </div>')
  },
  btcreate : {
    calendar : {
      start: "開始日",
      end: "終了日"
    },
    dateSummary : {
      notSelect: "※開始日、終了日を選択して下さい。",
      selected: new Template('<table class="values small" style="width:360px;" cellspacing="0" cellpadding="0">' +
      '            <tr><td class="label small" >期間</td><td class="value">#{range}</td></tr>' +
      '            <tr><td class="label small" >推定所要時間</td><td class="value">#{time} </td></tr>' +
      '        </table>'),
      error: "<span class='problem'>※開始日、終了日の設定が不正です。</span>"
    },
    start : {
      msg : "バックテストを開始します。よろしいですか?<br/>",
      success:  new Template("※開始しました。( #{dateStr} )"),
      error: new Template("<span class='problem'>※テストの開始に失敗しました。" +
      		"<pre style='width:350px;height:200px;overflow:scroll;font-size:11px;font-weight:normal'>#{error}</pre>" +
      		"</span>")
    }
  },
  rtsetting : {
    topicPath: "リアルトレード:設定",
    apply: {
        msg : "設定を反映します。よろしいですか?<br/>",
        success: new Template("※設定を反映しました。( #{dateStr} )"),
        error: new Template("<span class='problem'>※設定の反映に失敗しました。" +
            "<pre style='width:350px;height:200px;overflow:scroll;font-size:11px;font-weight:normal'>#{error}</pre>" +
            "</span>")
    },
    update : {
      op : {
        add: "追加",
        update: "更新",
        remove: "削除"
      },
      errorDetail : new Template("#{name}の#{operation}に失敗しました : #{cause}\n"),
      error: new Template("<span class='problem'>※設定の更新に失敗しました。" +
	      "<pre style='width:350px;height:200px;overflow:scroll;font-size:11px;font-weight:normal'>#{error}</pre>" +
	      "</span>")
    }
  },
  result :  {
    topicPath: {
      real :  "リアルトレード:状況を見る" ,
      backtest: "バックテスト:結果を見る:"
    },
    aggregate : {
      unknownAgent : "(不明)"
    },
    tradeEnable : {
      yes: "する",
      no: "しない"
    }
  },
  submenu : {
    info : {
      info : new Template(
          '  <table class="values large" cellspacing="0" cellpadding="0">' +
          '     <tr><td class="label large">名前</td><td class="value">#{name}</td></tr>' +
          '     <tr><td class="label large">期間</td><td class="value">#{range}</td></tr>' +
          '     <tr><td class="label large">メモ</td><td class="value"><pre>#{memo}</pre></td></tr>' +
          '  </table>'),
      rmtInfo : new Template(
          '  <table class="values large" cellspacing="0" cellpadding="0">' +
          '     <tr><td class="label large">自動取引</td><td class="value">#{enable}</td></tr>' +
          '  </table>')
    },
    trade : {
      summary : new Template (
          '<div id="summary" style="margin-top:10px;">'+
          '  <table class="values large" cellspacing="0" cellpadding="0">' +
          '     <tr><td class="label large">損益合計</td><td class="value">#{totalProfitOrLoss}</td></tr>' +
          '     <tr><td class="label large">累計スワップ</td><td class="value">#{totalSwap}</td></tr>' +
          '     <tr><td class="label large">総取引回数/約定済み</td><td class="value">#{total}/#{commited}</td></tr>' +
          '  </table>' +
          '  <div>' +
          '     <div style="float:left;width:300px;">' +
          '        <div class="category">種類</div>'+
          '        <table class="values small" cellspacing="0" cellpadding="0">' +
          '            <tr><td class="label small" >売</td><td class="value">#{sell}</td></tr>' +
          '            <tr><td class="label small" >買</td><td class="value">#{buy}</td></tr>' +
          '        </table>' +
          '        <div class="category">勝敗</div>'+
          '        <table class="values small" cellspacing="0" cellpadding="0">' +
          '            <tr><td class="label small" >勝ち/負け/引分</td><td class="value">#{win}/#{lose}/#{draw}</td></tr>' +
          '            <tr><td class="label small" >勝率</td><td class="value">#{winRate}%</td></tr>' +
          '        </table>' +
          '        <div class="category">通貨ペア</div>' +
          '        <table class="values small" cellspacing="0" cellpadding="0">' +
          '            #{pair}' +
          '        </table>' +
          '     </div>' +
          '     <div style="float:right;width:300px;">' +
          '        <div class="category">損益</div>'+
//          '        <div class="item"><div class="label_2">最大ドローダウン</div><div class="value">#{drawdown}</div><div class="breaker"></div></div>'+
          '        <table class="values small" cellspacing="0" cellpadding="0">' +
          '            <tr><td class="label small" >最大利益</td><td class="value">#{maxProfit}</td></tr>' +
          '            <tr><td class="label small" >最大損失</td><td class="value">#{maxLoss}</td></tr>' +
          '            <tr><td class="label small" >平均損益</td><td class="value">#{avgProfitOrLoss}</td></tr>' +
          '            <tr><td class="label small" >平均利益</td><td class="value">#{avgProfit}</td></tr>' +
          '            <tr><td class="label small" >平均損失</td><td class="value">#{avgLoss}</td></tr>' +
          '            <tr><td class="label small" >損益率</td><td class="value">#{profitRatio}</td></tr>' +
          '        </table>' +
          '        <div class="category">取引量</div>'+
          '        <table class="values small" cellspacing="0" cellpadding="0">' +
          '            <tr><td class="label small" >最大取引量</td><td class="value">#{maxSize}</td></tr>' +
          '            <tr><td class="label small" >最小取引量</td><td class="value">#{minSize}</td></tr>' +
          '        </table>' +
          '        <div class="category">建玉保有期間</div>'+
          '        <table class="values small" cellspacing="0" cellpadding="0">' +
          '            <tr><td class="label small" >最大保有期間</td><td class="value">#{maxRange}分</td></tr>' +
          '            <tr><td class="label small" >最小保有期間</td><td class="value">#{minRange}分</td></tr>' +
          '            <tr><td class="label small" >平均保有期間</td><td class="value">#{avgRange}分</td></tr>' +
          '        </table>' +
          '     </div>' +
          '   <div class="breaker"></div></div>' +
          '</div>'),
      pair : new Template (
          '<tr><td class="label small" >#{pair}</td><td class="value">#{value}</td></tr>' )
    },
    graph : {
      noAgent : '<div style="margin:10px 0px 0px 0px;">( グラフはありません。)</div>',
      agent : new Template(
          '  <div class="agent" id="output_#{id}">#{agentName} #{remove}</div>'+
          '  <table id="output_t_#{id}" class="graphs" cellspacing="0" cellpadding="0">' +
          '      #{items}'+
          '  </table>'),
      remove : new Template('<span class="output_delete">' +
      '<a href="javascript:void(0);" id="output_#{id}_delete"  title="グラフを削除" alt="グラフを削除">[グラフを削除]' +
      '</a>' +
      '</span>'),
      removeMsg : "グラフを削除します。よろしいですか?",
      item : new Template(
          '     <tr>' +
          '       <td>' +
          '         <input  type="checkbox"  alt="グラフを表示"  #{checked} id="submenu-graph_checked_#{id}" />' +
          '         <label for="submenu-graph_checked_#{id}" title="#{name}">#{name}</label>' +
          '       </td>' +
          '       <td class="color">#{colors}</td>'+
          '     </tr>' ),
       noGraphItem :
         '     <tr>' +
         '       <td>( グラフはありません。)</td>' +
         '     </tr>'
    }
  }
}