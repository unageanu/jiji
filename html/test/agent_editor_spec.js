

describe('fx.AgentEditorの動作確認', {

  // 前準備
  before : function() {
    JSONBrokerClientFactory.async = false;
    c = new container.Container( function( binder ){
      fx.modules.core( binder );
    });
    target = c.get("agentEditor");
    agentService = c.get("agentServiceStub");

    // ユーティリティ
    utils = {
      // 指定されたパスのファイル一覧を取得。
      list : function( path ){
        var names = null;
        target.list( path, function(result){
          names = result.map( function(item){
            return item.name + ":" + (item.type == "directory" ? "d" : "f");
          }, null);
        });
        return names;
      },
      // 指定されたパスのファイル本文を取得。
      get : function( path ){
        var body = null;
        target.get( path, function(result){
           body = result;
        });
        return body;
      },
      // 登録済みエージェントの一覧を取得。
      list_agents : function(){
        var agents = null;
        agentService.list_agent_class( function(result){
          agents = result;
        }, null);
        return agents;
      },
      // 選択して操作したのち、選択を解除する。
      selectWith : function( item, block ) {
        target.select( item );
        block();
        target.unselect( item );
      }
    }

    // 初期データ作成
    utils.selectWith( {path:"agents",type:"directory"}, function( ) {
      target.mkcol( "agent_editor_test" );
    });
    utils.selectWith( {path:"shared_lib",type:"directory"}, function( ) {
      target.mkcol( "agent_editor_test" );
    });
  },
  // 後始末
  after : function() {
    target.select( {path:"agents/agent_editor_test",type:"directory"} );
    target.select( {path:"shared_lib/agent_editor_test",type:"directory"} );
    target.removeSelections();
    JSONBrokerClientFactory.async = true;
  },
  
  'エージェントの追加/削除のテスト': function() {
    // 最初の一覧取得
    value_of( utils.list( "agents" ) ).should_include("agent_editor_test:d");
    value_of( utils.list( "shared_lib" ) ).should_include("agent_editor_test:d");

    // ファイル/フォルダを作成
    utils.selectWith( {path:"agents/agent_editor_test",type:"directory"}, function( ) {
	    target.add( "file1" );
	    target.add( "file2.rb" );
	    target.mkcol( "dir1" );
	    target.mkcol( "dir2" );
    });
    utils.selectWith( {path:"agents/agent_editor_test/dir1",type:"directory"}, function( ) {
      target.add( "file1-1" );
      target.add( "file1-2.rb" );
      target.mkcol( "dir1-1" );
    });
    utils.selectWith( {path:"agents/agent_editor_test/dir2",type:"directory"}, function( ) {
      target.add( "file2-1" );
      target.add( "file2-2.rb" );
      target.mkcol( "dir2-1" );
    });
    var list = utils.list( "agents/agent_editor_test" );
    value_of( list ).should_include("dir1:d");
		value_of( list ).should_include("dir2:d");
		value_of( list ).should_include("file1.rb:f");
    value_of( list ).should_include("file2.rb:f");

    list = utils.list( "agents/agent_editor_test/dir1" );
    value_of( list ).should_include("dir1-1:d");
    value_of( list ).should_include("file1-1.rb:f");
    value_of( list ).should_include("file1-2.rb:f");

    // ファイルを取得
    value_of( utils.get("agents/agent_editor_test/file1.rb") ).should_be("");
    value_of( utils.get("agents/agent_editor_test/file2.rb") ).should_be("");
    value_of( utils.get("agents/agent_editor_test/dir1/file1-1.rb") ).should_be("");
    value_of( utils.get("agents/agent_editor_test/dir1/file1-2.rb") ).should_be("");

    // ファイルを更新
    var body = 'class Test < JIJI::PeriodicallyAgent\n'
      + '  def description; "説明";end\n'
      + '  # UIから設定可能なプロパティの一覧を返す。\n'
      + '  def property_infos\n'
      + '    [Property.new( "short", "短期移動平均線", "", :string ),\n'
      + '      Property.new( "long",  "長期移動平均線", 30 )]\n'
      + '  end\n'
      + 'end';
    var body2 = 'class Test < JIJI::PeriodicallyAgent\n'
      + '  def description; "説明2";end\n'
      + '  # UIから設定可能なプロパティの一覧を返す。\n'
      + '  def property_infos\n'
      + '    [Property.new( "short", "短期移動平均線2", 25, :number ),\n'
      + '      Property.new( "long",  "長期移動平均線2", 75 )]\n'
      + '  end\n'
      + 'end';

    target.put( "agents/agent_editor_test/file1.rb", body, null,null);
    target.put( "agents/agent_editor_test/dir1/file1-1.rb", body2, null,null);
    target.put( "agents/agent_editor_test/dir1/file1-2.rb", "#コメント", null,null);
    value_of( utils.get("agents/agent_editor_test/file1.rb") ).should_be(body);
    value_of( utils.get("agents/agent_editor_test/file2.rb") ).should_be("");
    value_of( utils.get("agents/agent_editor_test/dir1/file1-1.rb") ).should_be(body2);
    value_of( utils.get("agents/agent_editor_test/dir1/file1-2.rb") ).should_be("#コメント");

    // エージェントが登録されていることを確認
    var agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1.rb" } );
    value_of( agent.class_name ).should_be( "Test" );
    value_of( agent.file_name ).should_be( "agent_editor_test/file1.rb" );
    value_of( agent.description ).should_be( "説明" );
    value_of( agent.properties[0] ).should_be( {
      id:"short", name:"短期移動平均線", "default":"", type:"string"
    });
    value_of( agent.properties[1] ).should_be( {
      id:"long", name:"長期移動平均線", "default":30, type:"string"
    });

    agent = agents.find( function(i){ return  i.class_name == "Test" && i.file_name=="agent_editor_test/dir1/file1-1.rb" } );
    value_of( agent.class_name ).should_be( "Test" );
    value_of( agent.file_name ).should_be( "agent_editor_test/dir1/file1-1.rb" );
    value_of( agent.description ).should_be( "説明2" );
    value_of( agent.properties[0] ).should_be( {
      id:"short", name:"短期移動平均線2", "default":25, type:"number"
    });
    value_of( agent.properties[1] ).should_be( {
      id:"long", name:"長期移動平均線2", "default":75, type:"string"
    });

    agent = agents.find( function(i){ return i.file_name=="agent_editor_test/dir1/file1-2.rb" } );
    value_of( agent ).should_be_undefined();


    // リネーム
    target.select( {path:"agents/agent_editor_test/file1.rb",type:"file"} );
    target.renameSelection( "file1_renamed", null, null );

    list = utils.list( "agents/agent_editor_test" );
    value_of( list ).should_include("dir1:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file1_renamed.rb:f");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "agents/agent_editor_test/file1.rb" ) ).should_be(false);
    value_of( target.isSelected( "agents/agent_editor_test/file1_renamed.rb" ) ).should_be(true);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1.rb" } );
    value_of( agent ).should_be_undefined();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1_renamed.rb" } );
    value_of( agent.class_name ).should_be( "Test" );
    value_of( agent.file_name ).should_be( "agent_editor_test/file1_renamed.rb" );
    value_of( agent.description ).should_be( "説明" );
    value_of( agent.properties[0] ).should_be( {
      id:"short", name:"短期移動平均線", "default":"", type:"string"
    });
    value_of( agent.properties[1] ).should_be( {
      id:"long", name:"長期移動平均線", "default":30, type:"string"
    });

    // フォルダをリネーム
    target.unselect( {path:"agents/agent_editor_test/file1_renamed.rb",type:"file"} );
    target.select( {path:"agents/agent_editor_test/dir1",type:"directory"} );
    target.renameSelection( "dir1_renamed", null, null );
    list = utils.list( "agents/agent_editor_test" );
    value_of( list ).should_include("dir1_renamed:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file1_renamed.rb:f");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "agents/agent_editor_test/dir1" ) ).should_be(false);
    value_of( target.isSelected( "agents/agent_editor_test/dir1_renamed" ) ).should_be(true);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/dir1/file1-1.rb" } );
    value_of( agent ).should_be_undefined();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/dir1_renamed/file1-1.rb" } );
    value_of( agent.class_name ).should_be( "Test" );
    value_of( agent.file_name ).should_be( "agent_editor_test/dir1_renamed/file1-1.rb" );
    value_of( agent.description ).should_be( "説明2" );
    value_of( agent.properties[0] ).should_be( {
      id:"short", name:"短期移動平均線2", "default":25, type:"number"
    });
    value_of( agent.properties[1] ).should_be( {
      id:"long", name:"長期移動平均線2", "default":75, type:"string"
    });


    // ファイルを削除
    target.unselect( {path:"agents/agent_editor_test/dir1_renamed",type:"directory"} );
    target.select( {path:"agents/agent_editor_test/file1_renamed.rb",type:"file"} );
    target.removeSelections( null, null );
    list = utils.list( "agents/agent_editor_test" );
    value_of( list ).should_include("dir1_renamed:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_not_include("file1_renamed.rb:f");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "agents/agent_editor_test/file1_renamed.rb" ) ).should_be(false);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1_renamed.rb" } );
    value_of( agent ).should_be_undefined();

    // フォルダを削除
    target.select( {path:"agents/agent_editor_test/dir1_renamed",type:"directory"} );
    target.removeSelections( null, null );
    list = utils.list( "agents/agent_editor_test" );
    value_of( list ).should_not_include("dir1_renamed:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "agents/agent_editor_test/dir1_renamed" ) ).should_be(false);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/dir1_renamed/file1-1.rb" } );
    value_of( agent ).should_be_undefined();


    // 一括削除
    target.select( {path:"agents/agent_editor_test/file2.rb",type:"file"} );
    target.select( {path:"agents/agent_editor_test/dir2",type:"directory"} );
    target.select( {path:"agents/agent_editor_test/dir2/file2-1",type:"directory"} );
    target.select( {path:"agents/agent_editor_test/dir2/dir2-1",type:"directory"} );
    target.removeSelections( null, null );
    list = utils.list( "agents/agent_editor_test" );
    value_of( list ).should_not_include("dir2:d");
    value_of( list ).should_not_include("file2.rb:f");

    value_of( target.isSelected( "agents/agent_editor_test/file2.rb" ) ).should_be(false);
    value_of( target.isSelected( "agents/agent_editor_test/dir2" ) ).should_be(false);


  },
 
  '共有ライブラリの追加/削除のテスト': function() {
    // 最初の一覧取得
    value_of( utils.list( "agents" ) ).should_include("agent_editor_test:d");
    value_of( utils.list( "shared_lib" ) ).should_include("agent_editor_test:d");

    // ファイル/フォルダを作成
    utils.selectWith( {path:"shared_lib/agent_editor_test",type:"directory"}, function( ) {
      target.add( "file1" );
      target.add( "file2.rb" );
      target.mkcol( "dir1" );
      target.mkcol( "dir2" );
    });
    utils.selectWith( {path:"shared_lib/agent_editor_test/dir1",type:"directory"}, function( ) {
      target.add( "file1-1" );
      target.add( "file1-2.rb" );
      target.mkcol( "dir1-1" );
    });
    var list = utils.list( "shared_lib/agent_editor_test" );
    value_of( list ).should_include("dir1:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file1.rb:f");
    value_of( list ).should_include("file2.rb:f");

    list = utils.list( "shared_lib/agent_editor_test/dir1" );
    value_of( list ).should_include("dir1-1:d");
    value_of( list ).should_include("file1-1.rb:f");
    value_of( list ).should_include("file1-2.rb:f");

    // ファイルを取得
    value_of( utils.get("shared_lib/agent_editor_test/file1.rb") ).should_be("");
    value_of( utils.get("shared_lib/agent_editor_test/file2.rb") ).should_be("");
    value_of( utils.get("shared_lib/agent_editor_test/dir1/file1-1.rb") ).should_be("");
    value_of( utils.get("shared_lib/agent_editor_test/dir1/file1-2.rb") ).should_be("");

    // ファイルを更新
    var body = 'class Test < JIJI::PeriodicallyAgent\n'
      + '  def description; "説明";end\n'
      + '  # UIから設定可能なプロパティの一覧を返す。\n'
      + '  def property_infos\n'
      + '    [Property.new( "short", "短期移動平均線", "", :string ),\n'
      + '      Property.new( "long",  "長期移動平均線", 30 )]\n'
      + '  end\n'
      + 'end';
    var body2 = 'class Test < JIJI::PeriodicallyAgent\n'
      + '  def description; "説明2";end\n'
      + '  # UIから設定可能なプロパティの一覧を返す。\n'
      + '  def property_infos\n'
      + '    [Property.new( "short", "短期移動平均線2", 25, :number ),\n'
      + '      Property.new( "long",  "長期移動平均線2", 75 )]\n'
      + '  end\n'
      + 'end';

    target.put( "shared_lib/agent_editor_test/file1.rb", body, null,null);
    target.put( "shared_lib/agent_editor_test/dir1/file1-1.rb", body2, null,null);
    target.put( "shared_lib/agent_editor_test/dir1/file1-2.rb", "#コメント", null,null);
    value_of( utils.get("shared_lib/agent_editor_test/file1.rb") ).should_be(body);
    value_of( utils.get("shared_lib/agent_editor_test/file2.rb") ).should_be("");
    value_of( utils.get("shared_lib/agent_editor_test/dir1/file1-1.rb") ).should_be(body2);
    value_of( utils.get("shared_lib/agent_editor_test/dir1/file1-2.rb") ).should_be("#コメント");

    // 共有ライブラリのクラスはエージェントとしてカウントされない。
    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.file_name=="agent_editor_test/file1.rb" } );
    value_of( agent ).should_be_undefined();

    agent = agents.find( function(i){ return i.file_name=="agent_editor_test/dir1/file1-1.rb" } );
    value_of( agent ).should_be_undefined();

    agent = agents.find( function(i){ return i.file_name=="agent_editor_test/dir1/file1-2.rb" } );
    value_of( agent ).should_be_undefined();


    // リネーム
    target.select( {path:"shared_lib/agent_editor_test/file1.rb",type:"file"} );
    target.renameSelection( "file1_renamed", null, null );

    list = utils.list( "shared_lib/agent_editor_test" );
    value_of( list ).should_include("dir1:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file1_renamed.rb:f");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "shared_lib/agent_editor_test/file1.rb" ) ).should_be(false);
    value_of( target.isSelected( "shared_lib/agent_editor_test/file1_renamed.rb" ) ).should_be(true);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/dir1/file1-1.rb" } );
    value_of( agent ).should_be_undefined();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/dir1_renamed/file1-1.rb" } );
    value_of( agent ).should_be_undefined();

    // フォルダをリネーム
    target.unselect( {path:"shared_lib/agent_editor_test/file1_renamed.rb",type:"file"} );
    target.select( {path:"shared_lib/agent_editor_test/dir1",type:"directory"} );
    target.renameSelection( "dir1_renamed", null, null );
    list = utils.list( "shared_lib/agent_editor_test" );
    value_of( list ).should_include("dir1_renamed:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file1_renamed.rb:f");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "shared_lib/agent_editor_test/dir1" ) ).should_be(false);
    value_of( target.isSelected( "shared_lib/agent_editor_test/dir1_renamed" ) ).should_be(true);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1.rb" } );
    value_of( agent ).should_be_undefined();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1_renamed.rb" } );
    value_of( agent ).should_be_undefined();


    // ファイルを削除
    target.unselect( {path:"shared_lib/agent_editor_test/dir1_renamed",type:"directory"} );
    target.select( {path:"shared_lib/agent_editor_test/file1_renamed.rb",type:"file"} );
    target.removeSelections( null, null );
    list = utils.list( "shared_lib/agent_editor_test" );
    value_of( list ).should_include("dir1_renamed:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_not_include("file1_renamed.rb:f");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "shared_lib/agent_editor_test/file1_renamed.rb" ) ).should_be(false);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/file1_renamed.rb" } );
    value_of( agent ).should_be_undefined();

    // フォルダを削除
    target.select( {path:"shared_lib/agent_editor_test/dir1_renamed",type:"directory"} );
    target.removeSelections( null, null );
    list = utils.list( "shared_lib/agent_editor_test" );
    value_of( list ).should_not_include("dir1_renamed:d");
    value_of( list ).should_include("dir2:d");
    value_of( list ).should_include("file2.rb:f");

    value_of( target.isSelected( "shared_lib/agent_editor_test/dir1_renamed" ) ).should_be(false);

    agents = utils.list_agents();
    agent = agents.find( function(i){ return i.class_name == "Test" && i.file_name=="agent_editor_test/dir1_renamed/file1-1.rb" } );
    value_of( agent ).should_be_undefined();


    // 一括削除
    target.select( {path:"shared_lib/agent_editor_test/file2.rb",type:"file"} );
    target.select( {path:"shared_lib/agent_editor_test/dir2",type:"directory"} );
    target.removeSelections( null, null );
    list = utils.list( "shared_lib/agent_editor_test" );
    value_of( list ).should_not_include("dir2:d");
    value_of( list ).should_not_include("file2.rb:f");

    value_of( target.isSelected( "shared_lib/agent_editor_test/file2.rb" ) ).should_be(false);
    value_of( target.isSelected( "shared_lib/agent_editor_test/dir2" ) ).should_be(false);

  },

  '追加の異常系テスト': function() {
    var t = target;
    var add = function( path, name ) {
      var result = null;
      t.select( {path:path,type:"directory"} );
      try {
        t.add( name, function(){
          result = "success";
        }, function( res ){
          result = res;
        } );
      } finally {
        t.unselect( {path:path,type:"directory"} );
      }
      return result;
    }
    
    // ファイル名が指定されていない
    var path = "agents/agent_editor_test";
    var msg = fx.template.Templates.common.errorMsg.emptyName;
    value_of( add( path, "" ).msg ).should_be( msg );
    value_of( add( path, null ).msg ).should_be( msg );
    value_of( add( path, undefined ).msg ).should_be( msg );
    
    // ファイル名が不正
    msg = fx.template.Templates.common.errorMsg.illegalName.evaluate({name:"ファイル"} );
    value_of( add( path, " " ).msg ).should_be( msg );
    value_of( add( path, "a " ).msg ).should_be( msg );
    value_of( add( path, "あ" ).msg ).should_be( msg );
    value_of( add( path, ":" ).msg ).should_be( msg );
    value_of( add( path, "/" ).msg ).should_be( msg );
    value_of( add( path, ">" ).msg ).should_be( msg );
    value_of( add( path, "<" ).msg ).should_be( msg );
    value_of( add( path, "@" ).msg ).should_be( msg );
    value_of( add( path, "*" ).msg ).should_be( msg );
    value_of( add( path, "\"" ).msg ).should_be( msg );
    value_of( add( path, "?" ).msg ).should_be( msg );
    value_of( add( path, "|" ).msg ).should_be( msg );
    value_of( add( path, ";" ).msg ).should_be( msg );
    value_of( add( path, "abc_+-#!~[]()'{}." ) ).should_be( "success" );
    
    // ファイルがすでに存在する
    utils.selectWith( {path:path,type:"directory"}, function( ) {
      target.add( "file1", null, null );
    });
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( add( path, "file1" ).msg ).should_be( msg );
    value_of( add( path, "file1.rb" ).msg ).should_be( msg );
    
    // フォルダがすでに存在する
    utils.selectWith( {path:path,type:"directory"}, function( ) {
      target.mkcol( "dir1" );
      target.mkcol( "dir1.rb" );
    });
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( add( path, "dir1" ).msg ).should_be( msg );
    value_of( add( path, "dir1.rb" ).msg ).should_be( msg );
    
    // 作成先が存在しない
    msg = fx.template.Templates.common.errorMsg.notFound.evaluate( {name:"ファイル"} ) ;
    value_of( add( "agents/agent_editor_test/not_found", "aaa" ).msg ).should_be( msg );
  },
  
  'フォルダ作成の異常系テスト': function() {
    var t = target;
    var mkcol = function( path, name ) {
      var result = null;
      t.select( {path:path,type:"directory"} );
      try {
        t.mkcol( name, function(){
          result = "success";
        }, function( res ){
          result = res;
        } );
      } finally {
        t.unselect( {path:path,type:"directory"} );
      }
      return result;
    }
    
    // フォルダ名が指定されていない
    var path = "agents/agent_editor_test";
    var msg = fx.template.Templates.common.errorMsg.emptyName;
    value_of( mkcol( path, "" ).msg ).should_be( msg );
    value_of( mkcol( path, null ).msg ).should_be( msg );
    value_of( mkcol( path, undefined ).msg ).should_be( msg );
    
    // フォルダ名が不正
    msg = fx.template.Templates.common.errorMsg.illegalName.evaluate({name:"ディレクトリ"} );
    value_of( mkcol( path, " " ).msg ).should_be( msg );
    value_of( mkcol( path, "a " ).msg ).should_be( msg );
    value_of( mkcol( path, "あ" ).msg ).should_be( msg );
    value_of( mkcol( path, ":" ).msg ).should_be( msg );
    value_of( mkcol( path, "/" ).msg ).should_be( msg );
    value_of( mkcol( path, ">" ).msg ).should_be( msg );
    value_of( mkcol( path, "<" ).msg ).should_be( msg );
    value_of( mkcol( path, "@" ).msg ).should_be( msg );
    value_of( mkcol( path, "*" ).msg ).should_be( msg );
    value_of( mkcol( path, "\"" ).msg ).should_be( msg );
    value_of( mkcol( path, "?" ).msg ).should_be( msg );
    value_of( mkcol( path, "|" ).msg ).should_be( msg );
    value_of( mkcol( path, ";" ).msg ).should_be( msg );
    value_of( mkcol( path, "abc_+-#!~[]()'{}." ) ).should_be( "success" );
    
    // ファイルがすでに存在する
    utils.selectWith( {path:path,type:"directory"}, function( ) {
      target.add( "file1", null, null );
    });
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( mkcol( path, "file1.rb" ).msg ).should_be( msg );
    
    // フォルダがすでに存在する
    utils.selectWith( {path:path,type:"directory"}, function( ) {
      target.mkcol( "dir1" );
    });
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( mkcol( path, "dir1" ).msg ).should_be( msg );
    
    // 作成先が存在しない
    msg = fx.template.Templates.common.errorMsg.notFound.evaluate( {name:"ディレクトリ"} ) ;
    value_of( mkcol( "agents/agent_editor_test/not_found", "aaa" ).msg ).should_be( msg );
  },
  
  'リネームの異常系テスト': function() {
    var t = target;
    
    utils.selectWith( {path:"agents/agent_editor_test",type:"directory"}, function( ) {
      target.add( "file1" );
      target.add( "file2.rb" );
      target.mkcol( "dir1" );
      target.mkcol( "dir2" );
      target.mkcol( "dir3.rb" );
    });
    
    var rename = function( name ) {
      var result = null;
      t.renameSelection( name, function(){
        result = "success";
      }, function( res ){
        result = res;
      } );
      return result;
    }
    
    // 名前が指定されていない
    var path = "agents/agent_editor_test/file1.rb";
    t.select( {path:path, type: "file"} );
    var msg = fx.template.Templates.common.errorMsg.emptyName;
    value_of( rename(  "" ).msg ).should_be( msg );
    value_of( rename(  null ).msg ).should_be( msg );
    value_of( rename(  undefined ).msg ).should_be( msg );
    
    // 名前が不正
    msg = fx.template.Templates.common.errorMsg.illegalName.evaluate({name:"ファイル"} );
    value_of( rename(  " " ).msg ).should_be( msg );
    value_of( rename(  "a " ).msg ).should_be( msg );
    value_of( rename(  "あ" ).msg ).should_be( msg );
    value_of( rename(  ":" ).msg ).should_be( msg );
    value_of( rename(  "/" ).msg ).should_be( msg );
    value_of( rename(  ">" ).msg ).should_be( msg );
    value_of( rename(  "<" ).msg ).should_be( msg );
    value_of( rename(  "@" ).msg ).should_be( msg );
    value_of( rename(  "*" ).msg ).should_be( msg );
    value_of( rename(  "\"" ).msg ).should_be( msg );
    value_of( rename(  "?" ).msg ).should_be( msg );
    value_of( rename(  "|" ).msg ).should_be( msg );
    value_of( rename(  ";" ).msg ).should_be( msg );
    value_of( rename(  "abc_+-#!~[]()'{}." ) ).should_be( "success" );
    t.renameSelection( "file1", null, null ) ;
    
    // ファイルがすでに存在する
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( rename(  "file2" ).msg ).should_be( msg );
    value_of( rename(  "file2.rb" ).msg ).should_be( msg );
    
    // フォルダがすでに存在する
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( rename(  "dir3" ).msg ).should_be( msg );
    value_of( rename(  "dir3.rb" ).msg ).should_be( msg );
    
    
    // ディレクトリをリネーム
    // 名前が指定されていない
    t.unselect( {path:path, type: "file"} );
    path = "agents/agent_editor_test/dir1";
    t.select( {path:path, type: "directory"} );
    var msg = fx.template.Templates.common.errorMsg.emptyName;
    value_of( rename(  "" ).msg ).should_be( msg );
    value_of( rename(  null ).msg ).should_be( msg );
    value_of( rename(  undefined ).msg ).should_be( msg );
    
    // 名前が不正
    msg = fx.template.Templates.common.errorMsg.illegalName.evaluate({name:"ディレクトリ"} );
    value_of( rename(  " " ).msg ).should_be( msg );
    value_of( rename(  "a " ).msg ).should_be( msg );
    value_of( rename(  "あ" ).msg ).should_be( msg );
    value_of( rename(  ":" ).msg ).should_be( msg );
    value_of( rename(  "/" ).msg ).should_be( msg );
    value_of( rename(  ">" ).msg ).should_be( msg );
    value_of( rename(  "<" ).msg ).should_be( msg );
    value_of( rename(  "@" ).msg ).should_be( msg );
    value_of( rename(  "*" ).msg ).should_be( msg );
    value_of( rename(  "\"" ).msg ).should_be( msg );
    value_of( rename(  "?" ).msg ).should_be( msg );
    value_of( rename(  "|" ).msg ).should_be( msg );
    value_of( rename(  ";" ).msg ).should_be( msg );
    value_of( rename(  "abc_+-#!~[]()'{}." ) ).should_be( "success" );
    t.renameSelection( "dir1", null, null ) ;
    
    // ファイルがすでに存在する
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( rename(  "file1.rb" ).msg ).should_be( msg );
    
    // フォルダがすでに存在する
    msg = fx.template.Templates.common.errorMsg.alreadyExist ;
    value_of( rename(  "dir2" ).msg ).should_be( msg );
    
    // エージェント/共有ライブラリをリネーム
    t.unselect( {path:path, type: "directory"} );
    msg = fx.template.Templates.common.errorMsg.systemError ;
    utils.selectWith( {path:"agents",type:"directory"}, function( ) {
      value_of( rename( "aaa" ).msg ).should_be( msg );
    });
    utils.selectWith( {path:"shared_lib",type:"directory"}, function( ) {
      value_of( rename( "bbb" ).msg ).should_be( msg );
    });
    
    // 対象が存在しない
    msg = fx.template.Templates.common.errorMsg.notFound.evaluate( {name:"ディレクトリ"} ) ;
    utils.selectWith( {path:"agents/not_found",type:"directory"}, function( ) {
      value_of( rename( "aaa" ).msg ).should_be( msg );
    });
    msg = fx.template.Templates.common.errorMsg.notFound.evaluate( {name:"ファイル"} ) ;
    utils.selectWith( {path:"agents/not_found",type:"file"}, function( ) {
      value_of( rename( "aaa" ).msg ).should_be( msg );
    });
  },

  '削除の異常系テスト': function() {

    var t = target;
    
    utils.selectWith( {path:"agents/agent_editor_test",type:"directory"}, function( ) {
      target.add( "file1" );
      target.add( "file2.rb" );
      target.mkcol( "dir1" );
      target.mkcol( "dir2" );
    });
    
    var remove = function( paths ) {
      var result = null;
      for ( var i=0; i < paths.length; i++ ) {
        t.select( paths[i] );
      }
      t.removeSelections( function( res ){
        result = res;
      }, function( res ){
        result = res;
      } );
      for ( i=0; i < paths.length; i++ ) {
        t.unselect( paths[i] );
      }
      return result;
    }
    
    // 削除対象が存在しない
    var msg = fx.template.Templates.common.errorMsg.notFound.evaluate( {name:"ディレクトリ"} ) ;
    var res = remove(  [{path:"agents/not_found",type:"directory"}] );
    value_of( res.success["agents/not_found"] ).should_be_undefined( );
    value_of( res.failed["agents/not_found"].msg ).should_be( msg );
    
    var msg2 = fx.template.Templates.common.errorMsg.notFound.evaluate( {name:"ファイル"} ) ;
    res = remove(  [{path:"agents/not_found",type:"file"}] );
    value_of( res.success["agents/not_found"] ).should_be_undefined( );
    value_of( res.failed["agents/not_found"].msg ).should_be( msg2 );
    
    // 複数選択し、一部のみ削除失敗
    res = remove(  [
      {path:"agents/not_found",type:"file"},
      {path:"agents/not_found2",type:"directory"},
      {path:"agents/agent_editor_test/file1.rb",type:"file"},
      {path:"agents/agent_editor_test/dir1",type:"directory"}
    ] );
    value_of( res.success["agents/not_found"] ).should_be_undefined( );
    value_of( res.success["agents/not_found2"] ).should_be_undefined( );
    value_of( res.success["agents/agent_editor_test/file1.rb"].path ).should_be( "agents/agent_editor_test/file1.rb" );
    value_of( res.success["agents/agent_editor_test/dir1"].path ).should_be( "agents/agent_editor_test/dir1" );
    value_of( res.failed["agents/not_found"].msg ).should_be( msg2 );
    value_of( res.failed["agents/not_found2"].msg ).should_be( msg );
    
    // エージェント/共有ライブラリを削除
    msg = fx.template.Templates.common.errorMsg.systemError ;
    value_of( remove(  [{path:"agents",type:"directory"}] ).msg ).should_be( msg );
    value_of( remove(  [{path:"shared_lib",type:"directory"}] ).msg ).should_be( msg );
  },
  
  '選択のテスト': function() {
    value_of( target.isSelected( "agents/agent_editor_test" ) ).should_be(false);
    value_of( target.isSelected( "shared_lib/agent_editor_test" ) ).should_be(false);

    target.select( {path:"agents/agent_editor_test",type:"directory"} );
    value_of( target.isSelected( "agents/agent_editor_test" ) ).should_be(true);
    value_of( target.isSelected( "shared_lib/agent_editor_test" ) ).should_be(false);

    target.select( {path:"shared_lib/agent_editor_test",type:"directory"} );
    value_of( target.isSelected( "agents/agent_editor_test" ) ).should_be(true);
    value_of( target.isSelected( "shared_lib/agent_editor_test" ) ).should_be(true);

    target.unselect( {path:"agents/agent_editor_test",type:"directory"} );
    value_of( target.isSelected( "agents/agent_editor_test" ) ).should_be(false);
    value_of( target.isSelected( "shared_lib/agent_editor_test" ) ).should_be(true);

    target.unselect( {path:"shared_lib/agent_editor_test",type:"directory"} );
    value_of( target.isSelected( "agents/agent_editor_test" ) ).should_be(false);
    value_of( target.isSelected( "shared_lib/agent_editor_test" ) ).should_be(false);
  },
  
  '実行可/不可判定のテスト': function() {

    var t = target;

    // テストデータ作成
    utils.selectWith( {path:"agents/agent_editor_test",type:"directory"}, function( ) {
       t.add( "file1" );
       t.add( "file2" );
       t.mkcol( "dir1" );
       t.mkcol( "dir2" );
    });

    // 選択なしの場合
    value_of( target.enable( "add" ) ).should_be(false);
    value_of( target.enable( "mkcol" ) ).should_be(false);
    value_of( target.enable( "renameSelection" ) ).should_be(false);
    value_of( target.enable( "moveSelections" ) ).should_be(false);
    value_of( target.enable( "removeSelections" ) ).should_be(false);

    // ファイルを1つだけ選択
    target.select( {path:"agents/agent_editor_test/file1",type:"file"} );
    value_of( target.enable( "add" ) ).should_be(false);
    value_of( target.enable( "mkcol" ) ).should_be(false);
    value_of( target.enable( "renameSelection" ) ).should_be(true);
    value_of( target.enable( "moveSelections" ) ).should_be(true);
    value_of( target.enable( "removeSelections" ) ).should_be(true);

    // ファイルを複数選択
    target.select( {path:"agents/agent_editor_test/file2",type:"file"} );
    value_of( target.enable( "add" ) ).should_be(false);
    value_of( target.enable( "mkcol" ) ).should_be(false);
    value_of( target.enable( "renameSelection" ) ).should_be(false);
    value_of( target.enable( "moveSelections" ) ).should_be(true);
    value_of( target.enable( "removeSelections" ) ).should_be(true);

    //フォルダを1つ選択
    target.unselect( {path:"agents/agent_editor_test/file1",type:"file"} );
    target.unselect( {path:"agents/agent_editor_test/file2",type:"file"} );
    target.select( {path:"agents/agent_editor_test/dir1",type:"directory"} );
    value_of( target.enable( "add" ) ).should_be(true);
    value_of( target.enable( "mkcol" ) ).should_be(true);
    value_of( target.enable( "renameSelection" ) ).should_be(true);
    value_of( target.enable( "moveSelections" ) ).should_be(true);
    value_of( target.enable( "removeSelections" ) ).should_be(true);

    // フォルダを複数選択
    target.select( {path:"agents/agent_editor_test/dir2",type:"directory"} );
    value_of( target.enable( "add" ) ).should_be(false);
    value_of( target.enable( "mkcol" ) ).should_be(false);
    value_of( target.enable( "renameSelection" ) ).should_be(false);
    value_of( target.enable( "moveSelections" ) ).should_be(true);
    value_of( target.enable( "removeSelections" ) ).should_be(true);

    // ファイルとフォルダを選択
    target.unselect( {path:"agents/agent_editor_test/dir1",type:"directory"} );
    target.select( {path:"agents/agent_editor_test/file1",type:"file"} );
    value_of( target.enable( "add" ) ).should_be(false);
    value_of( target.enable( "mkcol" ) ).should_be(false);
    value_of( target.enable( "renameSelection" ) ).should_be(false);
    value_of( target.enable( "moveSelections" ) ).should_be(true);
    value_of( target.enable( "removeSelections" ) ).should_be(true);
    
    // agentsが選択されている
    target.unselect( {path:"agents/agent_editor_test/file1",type:"file"} );
    target.unselect( {path:"agents/agent_editor_test/dir2",type:"directory"} );
    target.select( {path:"agents",type:"directory"} );
    value_of( target.enable( "add" ) ).should_be(true);
    value_of( target.enable( "mkcol" ) ).should_be(true);
    value_of( target.enable( "renameSelection" ) ).should_be(false);
    value_of( target.enable( "moveSelections" ) ).should_be(false);
    value_of( target.enable( "removeSelections" ) ).should_be(false);
    
    // shared_lib
    target.unselect(  {path:"agents",type:"directory"}  );
    target.select( {path:"shared_lib",type:"directory"} );
    value_of( target.enable( "add" ) ).should_be(true);
    value_of( target.enable( "mkcol" ) ).should_be(true);
    value_of( target.enable( "renameSelection" ) ).should_be(false);
    value_of( target.enable( "moveSelections" ) ).should_be(false);
    value_of( target.enable( "removeSelections" ) ).should_be(false);
  }

});