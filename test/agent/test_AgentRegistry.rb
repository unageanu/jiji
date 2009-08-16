#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/agent/agent'
require 'jiji/agent/agent_manager'
require 'jiji/agent/agent_registry'
require 'jiji/agent/permitter'
require 'jiji/agent/util'
require 'jiji/configuration'
require 'jiji/dao/file_system_dao'
require 'fileutils'

# AgentRegistory のテスト
class AgentRegistryTest <  RUNIT::TestCase
  include JIJI::AgentUtil
  def setup
    @dir = File.dirname(__FILE__) + "/agents"
    FileUtils.mkdir_p @dir

    @dao =  JIJI::Dao::FileSystemDao.new( @dir )
    @dao.mkcol "agents"
    @dao.mkcol "shared"

    @registry = JIJI::AgentRegistry.new( "agents", "shared" )
    @registry.conf = JIJI::Configuration.new
    @registry.file_dao = @dao
    @registry.server_logger = Logger.new STDOUT
  end

  def teardown
    FileUtils.rm_rf @dir
    sleep 1
  end

  # 基本動作のテスト
  def test_basic

    # 最初は空
    assert_equals @registry.collect, []

    # 追加
    foo_body = "class Foo; include JIJI::Agent; end"
    var_body = <<-BODY
    class Var
      include JIJI::Agent
      def test
        [JIJI::Agent::Shared::VALUE, JIJI::Agent::Shared::SharedLib.new, JIJI::Agent::Shared.m] # 共有ライブラリのAPIを使用。
      end
    end
BODY

    assert_equals @dao.put( "agents/foo.rb", foo_body ), :success
    assert_equals @dao.put( "agents/var.rb", var_body ), :success
    @registry.load( "agents/foo.rb" )
    @registry.load( "agents/var.rb" )

    assert_equals @registry.collect.sort!, ["Foo@foo.rb", "Var@var.rb"]
    assert_agent_files @dao.list("agents"), ["foo.rb","var.rb"]
    assert_agent_files @dao.list("shared"), []


    # 取得
    cl = @registry.get "Foo@foo.rb"
    assert_not_nil cl
    cl.new # インスタンスを生成できるのを確認

    cl = @registry.get "Var@var.rb"
    assert_not_nil cl
    obj = safe(4) {cl.new}
    begin
      obj.test
      fail
    rescue
    end

    # 共有ライブラリを追加。
    shared_lib_body = <<-BODY
    VALUE="val"
    class SharedLib
      def foo
        "fooo" # 共有ライブラリのAPIを使用。
      end
    end
    def self.m
      "method called."
    end
BODY
    assert_equals @dao.put( "shared/shared_lib.rb", shared_lib_body ), :success
    @registry.load( "shared/shared_lib.rb" )

    # 一覧
    assert_equals @registry.collect.sort!, ["Foo@foo.rb", "Var@var.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb","var.rb"]
    assert_agent_files @dao.list( "shared" ), ["shared_lib.rb"]

    # 共有ライブラリを呼び出すAPIが利用可能になる。
    assert_equals( safe(4) { obj.test[0] }, "val")
    assert_equals( safe(4) { obj.test[1].foo}, "fooo" )
    assert_equals( safe(4) { obj.test[2] }, "method called.")

    begin
      @registry.get("Not_Found@notfound.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @registry.get("Not_Found@foo.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @registry.get("Not::Not_Found@foo.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

    #ファイル取得
    assert_equals @dao.get( "agents/foo.rb" ), foo_body
    assert_equals @dao.get( "agents/var.rb" ), var_body
    assert_equals @dao.get( "shared/shared_lib.rb" ), shared_lib_body
    begin
      @dao.get( "agents/Not_Found" )
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @dao.get( "shared/Not_Found" )
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @dao.get( "shared/foo.rb" )
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

    # 上書き更新
     var_body = <<-BODY
    class Var2
      include JIJI::Agent
      def test
        [JIJI::Agent::Shared::VALUE, JIJI::Agent::Shared::SharedLib.new, "xx"] # 共有ライブラリのAPIを使用。
      end
    end
BODY
    assert_equals @dao.put( "agents/var.rb", var_body ), :success
    @registry.load( "agents/var.rb" )

    assert_equals @registry.collect.sort!, ["Foo@foo.rb", "Var2@var.rb"]
    assert_agent_files @dao.list("agents"), ["foo.rb","var.rb"]

    assert_equals @dao.get( "agents/foo.rb" ), foo_body
    assert_equals @dao.get( "agents/var.rb" ), var_body
    assert_equals @dao.get( "shared/shared_lib.rb" ), shared_lib_body

    cl = @registry.get "Var2@var.rb"
    assert_not_nil cl
    obj = @registry.create("Var2@var.rb",{})

    assert_equals( safe(4) { obj.test[0] }, "val")
    assert_equals( safe(4) { obj.test[1].foo}, "fooo" )
    assert_equals( safe(4) { obj.test[2] }, "xx")

    # 古いクラスは利用不可
    begin
      @registry.get("Var@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

    # レジストリを再作成
    @registry = JIJI::AgentRegistry.new( "agents", "shared" )
    @registry.conf = JIJI::Configuration.new
    @registry.file_dao = @dao
    @registry.server_logger = Logger.new STDOUT

    assert_equals @registry.collect, []
    assert_agent_files @dao.list( "agents" ), ["foo.rb","var.rb"]
    assert_agent_files @dao.list( "shared" ), ["shared_lib.rb"]

    # 再読み込み
    @registry.load_all
    assert_equals @registry.collect.sort!, ["Foo@foo.rb", "Var2@var.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb","var.rb"]
    assert_agent_files @dao.list( "shared" ), ["shared_lib.rb"]

    # 共有ライブラリを削除
    #ライブラリ内のクラスは利用不可
    @dao.delete( "shared/shared_lib.rb" )
    @registry.unload( "shared/shared_lib.rb" )
    assert_equals @registry.collect.sort!, ["Foo@foo.rb", "Var2@var.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb","var.rb"]
    assert_agent_files @dao.list( "shared" ), []

    cl = @registry.get "Var2@var.rb"
    assert_not_nil cl
    obj = @registry.create("Var2@var.rb",{})
    begin
      safe(4) { obj.test[0] }
    rescue NameError
    end
    #assert_equals( safe(4) { obj.test[0] }, "val")
    #assert_equals( safe(4) { obj.test[1].foo}, "fooo" )
    #assert_equals( safe(4) { obj.test[2] }, "xx")

    begin
      @dao.delete( "shared/NotFound" )
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

    # 削除
    @dao.delete( "agents/var.rb" )
    @registry.unload( "agents/var.rb" )
    assert_equals @registry.collect.sort!, ["Foo@foo.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb"]
    assert_agent_files @dao.list( "shared" ), []

    begin
      @dao.delete( "NotFound" )
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

    assert_equals @registry.collect.sort!, ["Foo@foo.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb"]

    # 削除したクラスは利用不可
    cl = @registry.get "Foo@foo.rb"
    assert_not_nil cl
    begin
      @registry.get("Var2@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

    # レジストリを再作成
    @registry = JIJI::AgentRegistry.new( "agents", "shared" )
    @registry.conf = JIJI::Configuration.new
    @registry.file_dao = @dao
    @registry.server_logger = Logger.new STDOUT

    @registry.load_all
    assert_equals @registry.collect.sort!, ["Foo@foo.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb"]
    assert_agent_files @dao.list( "shared" ), []

     cl = @registry.get "Foo@foo.rb"
    assert_not_nil cl

    # 再登録
    str = <<-CLASS_DEF
    class Var; include JIJI::Agent; end
    module Xx
      class Var2_1; include JIJI::Agent; end
      class Var2_2; include JIJI::Agent; end
      module Yy
        class Var2_3; include JIJI::Agent; end
      end
      class X; end
      Y = "foo"
    end
    class Var3; include JIJI::Agent; end
    class A; end
    class S
      include JIJI::Agent
      def test
        JIJI::Agent::Shared::VALUE
      end
    end
CLASS_DEF
    @dao.put( "agents/var.rb", str )
    @registry.load( "agents/var.rb" )
    assert_equals @registry.collect.sort!, ["Foo@foo.rb",  "S@var.rb", "Var3@var.rb", "Var@var.rb", "Xx::Var2_1@var.rb", "Xx::Var2_2@var.rb","Xx::Yy::Var2_3@var.rb"]
    assert_agent_files @dao.list( "agents" ), ["foo.rb","var.rb"]

    # 取得
    begin
      assert_nil @registry.get("A@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @registry.get("Xx@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @registry.get("Xx::Y@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @registry.get("Xx::X@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
    begin
      @registry.get("Xx::Yy@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end

  end

  # エージェントファイル一覧を確認する。
  def assert_agent_files( files,  expects )
    assert_equals files.length, expects.length
    files.each_index { |i|
      # 名前が取得できることを確認。最終更新日時は設定されていることのみ確認
      assert_equals expects[i], files[i][:name]
      assert_not_nil files[i][:update]
    }
  end

  # プロパティ一覧のテスト
  def test_properties
    str =<<-AGENT_STR
      class Foo
        include JIJI::Agent
        def initialize
          @a = 1
          @b = "foo"
          @c = 0.1
        end
        def property_infos
          [
            Property.new( "a", "aaa", 1 ),
            Property.new( "b", "bbb", "foo" ),
            Property.new( "c", "ccc", 0.1 )
          ]
        end
        def description
          "テスト"
        end
        attr :a, true
        attr :b, true
        attr :c, true
      end
    AGENT_STR

    @dao.put( "agents/foo.rb", str )
    @registry.load( "agents/foo.rb" )

    ps = @registry.get_property_infos "Foo@foo.rb"
    assert_equals ps, [
      JIJI::Agent::Property.new( "a", "aaa", 1 ),
      JIJI::Agent::Property.new( "b", "bbb", "foo" ),
      JIJI::Agent::Property.new( "c", "ccc", 0.1 )
    ]

    agent = @registry.create( "Foo@foo.rb" )
    assert_equals [1,"foo", 0.1], safe(4){
      # エージェントはデフォルトではsafeレベル4で実行されるため、汚染されている。
	    # safeレベル0では呼び出せない。
      [agent.a, agent.b, agent.c]
    }
    agent = @registry.create( "Foo@foo.rb", {
      "a" => 100, "b" => "test", "c" => 0.34
    })
    assert_equals [100,"test", 0.34],safe(4){
	    [agent.a, agent.b, agent.c]
    }

    # 説明の取得
    assert_equals "テスト", @registry.get_description("Foo@foo.rb")
  end

  # クラス更新のテスト
  def test_update
    str = <<-CLASS_DEF
  module Test
    class Foo
      include JIJI::Agent
      def test
       "test"
      end
    end
  end
CLASS_DEF
    @dao.put( "agents/var.rb", str )
    @registry.load( "agents/var.rb" )

    agent = @registry.create "Test::Foo@var.rb"
    assert_equals "test", safe(4){
      agent.test
    }

    # クラスを更新
    str = <<-CLASS_DEF
  module Test
    class Foo
      include JIJI::Agent
      def test
       "test2"
      end
    end
  end
CLASS_DEF
    @dao.put( "agents/var.rb", str )
    @registry.load( "agents/var.rb" )

    agent2 = @registry.create "Test::Foo@var.rb"
    assert_equals ["test","test2"], safe(4){
      [agent.test, agent2.test] # 古いクラスも再作成されるまでは有効
    }

    # コンパイルエラーになる場合
    str = <<-CLASS_DEF
  module Test
    class Foo
      include JIJI::Agent
      def test
       "test"
      end
    end
CLASS_DEF
    @dao.put( "agents/var.rb", str )
    begin
      @registry.load( "agents/var.rb" )
      fail
    rescue SyntaxError
    end

    begin
      @registry.get("Test::Foo@var.rb")
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
  end

  # 共有ライブラリの更新
  def test_update_sharedlib

    # 共有ライブラリを使うクラス
    @dao.put "agents/foo.rb", <<-BODY
    class Var
      include JIJI::Agent
      def init
        @s = JIJI::Agent::Shared::SharedLib.new
      end
      def test
        [JIJI::Agent::Shared::VALUE, JIJI::Agent::Shared::SharedLib.new, JIJI::Agent::Shared.m] # 共有ライブラリのAPIを使用。
      end
      def test2
        [JIJI::Agent::Shared::VALUE2, JIJI::Agent::Shared::SharedLib2.new, JIJI::Agent::Shared.m2] # 共有ライブラリのAPIを使用。
      end
      attr_reader :s
    end
BODY
    @registry.load( "agents/foo.rb" )

    obj = @registry.create("Var@foo.rb",{})

    # まだ共有ライブラリがないのでエラー
    begin
      safe(4) { obj.test }
      fail
    rescue
    end
    begin
      safe(4) { obj.init }
      fail
    rescue
  end

    # 共有ライブラリを定義
    shared_lib_body = <<-BODY
    VALUE='val'
    class SharedLib
      def foo
        "fooo"
      end
    end
    def self.m
      "method called."
    end
BODY
    assert_equals @dao.put( "shared/shared_lib.rb", shared_lib_body ), :success
    @registry.load( "shared/shared_lib.rb" )

    assert_equals safe(4){obj.test[0]},  'val'
    assert_equals safe(4){obj.test[1].foo},  'fooo'
    assert_equals safe(4){obj.test[2]},  'method called.'

    safe(4){ obj.init }
    assert_equals safe(4){obj.s.foo},  'fooo'

    obj2 = @registry.create("Var@foo.rb", {})
    assert_equals safe(4){obj2.test[0]},  'val'
    assert_equals safe(4){obj2.test[1].foo},  'fooo'
    assert_equals safe(4){obj2.test[2]},  'method called.'
    safe(4){ obj2.init }
    assert_equals safe(4){obj2.s.foo},  'fooo'

    # テスト2はまだ呼び出せない
    begin
      safe(4) { obj.test2 }
      fail
    rescue; end
    begin
      safe(4) { obj2.test2 }
      fail
    rescue; end

    # 共有ライブラリ2を追加
    shared_lib_body = <<-BODY
    VALUE2=JIJI::Agent::Shared::VALUE + ":" +JIJI::Agent::Shared.m
    class SharedLib2 < JIJI::Agent::Shared::SharedLib
      def foo2
        JIJI::Agent::Shared.m + ":" + JIJI::Agent::Shared::SharedLib.new.foo
      end
    end
    def self.m2
      JIJI::Agent::Shared.m
    end
BODY
    assert_equals @dao.put( "shared/shared_lib2.rb", shared_lib_body ), :success
    @registry.load( "shared/shared_lib2.rb" )

    assert_equals safe(4){obj.test[0]},  'val'
    assert_equals safe(4){obj.test[1].foo},  'fooo'
    assert_equals safe(4){obj.test[2]},  'method called.'
    assert_equals safe(4){obj2.test[0]},  'val'
    assert_equals safe(4){obj2.test[1].foo},  'fooo'
    assert_equals safe(4){obj2.test[2]},  'method called.'
    assert_equals safe(4){obj.s.foo},  'fooo'
    assert_equals safe(4){obj2.s.foo},  'fooo'

    assert_equals safe(4){obj.test2[0]},  'val:method called.'
    assert_equals safe(4){obj.test2[1].foo},  'fooo'
    assert_equals safe(4){obj.test2[1].foo2},  'method called.:fooo'
    assert_equals safe(4){obj.test2[2]},  'method called.'
    assert_equals safe(4){obj2.test2[0]},  'val:method called.'
    assert_equals safe(4){obj2.test2[1].foo},  'fooo'
    assert_equals safe(4){obj2.test2[1].foo2},  'method called.:fooo'
    assert_equals safe(4){obj2.test2[2]},  'method called.'

    # 共有ライブラリを上書き更新
    shared_lib_body = <<-BODY
    VALUE='val2'
    class SharedLib
      def foo
        "fooo2"
      end
    end
    def self.m
      "method called2."
    end
BODY
    assert_equals @dao.put( "shared/shared_lib.rb", shared_lib_body ), :success
    @registry.load( "shared/shared_lib.rb" )

    assert_equals safe(4){obj.test[0]},  'val2'
    assert_equals safe(4){obj.test[1].foo},  'fooo2'
    assert_equals safe(4){obj.test[2]},  'method called2.'
    assert_equals safe(4){obj2.test[0]},  'val2'
    assert_equals safe(4){obj2.test[1].foo},  'fooo2'
    assert_equals safe(4){obj2.test[2]},  'method called2.'
    # すでに作成済みのインスタンスの動作は変わらない
    assert_equals safe(4){obj.s.foo},  'fooo'
    assert_equals safe(4){obj2.s.foo},  'fooo'
    # 再作成すると変わる
    safe(4){
      obj.init
      obj2.init
    }
    assert_equals safe(4){obj.s.foo},  'fooo2'
    assert_equals safe(4){obj2.s.foo},  'fooo2'

    # 依存モジュール内からの呼び出し結果も変わる
    assert_equals safe(4){obj.test2[0]},  'val:method called.' # 定数は定義の段階で評価されているので変わらない
    assert_equals safe(4){obj.test2[1].foo},  'fooo'
    assert_equals safe(4){obj.test2[1].foo2},  'method called2.:fooo2'
    assert_equals safe(4){obj.test2[2]},  'method called2.'
    assert_equals safe(4){obj2.test2[0]},  'val:method called.'
    assert_equals safe(4){obj2.test2[1].foo},  'fooo'
    assert_equals safe(4){obj2.test2[1].foo2},  'method called2.:fooo2'
    assert_equals safe(4){obj2.test2[2]},  'method called2.'
  end

  #階層構造を作成し、load_allするテスト。
  def test_deep_directory

    # 最初は空
    assert_equals @registry.collect, []

    # エージェントを追加
    foo_body = "class Foo; include JIJI::Agent; end"
    var_body = <<-BODY
    class Var
      include JIJI::Agent
      def var
        [JIJI::Agent::Shared::VALUE_D1, JIJI::Agent::Shared::VALUE_D2] # 共有ライブラリのAPIを使用。
      end
    end
BODY

    @dao.mkcol "agents/folder1"
    @dao.mkcol "agents/folder1/folder2"

    assert_equals @dao.put( "agents/folder1/foo.rb", foo_body ), :success
    assert_equals @dao.put( "agents/folder1/folder2/var.rb", var_body ), :success
    @registry.load( "agents/folder1/foo.rb" )
    @registry.load( "agents/folder1/folder2/var.rb" )

    assert_equals @registry.collect.sort!, ["Foo@folder1/foo.rb", "Var@folder1/folder2/var.rb"]

    obj = @registry.create("Var@folder1/folder2/var.rb",{})
    begin
      safe(4) { obj.var } #共有ライブラリが追加されていないのでエラーになる
      fail
    rescue; end

    # 共有ライブラリを追加
    @dao.mkcol "shared/folder1"
    @dao.mkcol "shared/folder1/folder2"

    shared_lib_body  = "VALUE_D1='val'"
    shared_lib_body2 = "VALUE_D2='val2'"
    assert_equals @dao.put( "shared/folder1/shared_lib.rb", shared_lib_body ), :success
    assert_equals @dao.put( "shared/folder1/folder2/shared_lib.rb", shared_lib_body2 ), :success
    @registry.load( "shared/folder1/shared_lib.rb" )
    @registry.load( "shared/folder1/folder2/shared_lib.rb" )

    #定数が定義され、varメソッドが実行できるようになる
    assert_equals safe(4) { obj.var }, ["val", "val2"]


    # レジストリを再構築
    @registry = JIJI::AgentRegistry.new( "agents", "shared" )
    @registry.conf = JIJI::Configuration.new
    @registry.file_dao = @dao
    @registry.server_logger = Logger.new STDOUT
    @registry.load_all

    #エージェントと共有ライブラリが全てロードされていることを確認
    assert_equals @registry.collect.sort!, ["Foo@folder1/foo.rb", "Var@folder1/folder2/var.rb"]
    obj = @registry.create("Var@folder1/folder2/var.rb",{})
    assert_equals safe(4) { obj.var }, ["val", "val2"]
  end

end

