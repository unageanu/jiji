#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/process'
require 'jiji/registry'
require 'logger'
require 'test_utils'

# プロセスのテスト
class ProcessTest <  RUNIT::TestCase

  include Test::Constants

  def setup
    @dir = File.dirname(__FILE__) + "/ProcessTest"
    FileUtils.mkdir_p @dir
    @registry = JIJI::Registry.new(@dir , nil)
    @registry.plugin_loader.load
  end

  def teardown
    begin
      Test.destry( @registry, @dir )
    ensure
      FileUtils.rm_rf "#{@dir}/process_info_test"
    end
  end

  # ProcessInfoの基本操作のテスト
  def test_process_info

    dir = "#{@dir}/process_info_test"

    p1 = JIJI::ProcessInfo.new( "1", dir )
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {}
    assert_equals p1["x"], nil
    assert_equals p1.progress, 0
    assert_equals p1.data_exist?, false

    #プロパティを設定。データがファイルに保存される。
    p1.props = {"x"=>"xxx", "y"=>"yyy"}
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {"x"=>"xxx", "y"=>"yyy"}
    assert_equals p1["x"], "xxx"
    assert_equals p1["y"], "yyy"
    assert_equals p1.progress, 0
    assert_equals p1.data_exist?, true


    #再作成
    p1 = JIJI::ProcessInfo.new( "1", dir )
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {}
    assert_equals p1["x"], nil
    assert_equals p1.progress, 0
    assert_equals p1.data_exist?, true

    #保存されたデータを読み込み
    p1.load
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {"x"=>"xxx", "y"=>"yyy"}
    assert_equals p1["x"], "xxx"
    assert_equals p1["y"], "yyy"
    assert_equals p1.progress, 0

    #プロパティを変更
    p1["x"] = "aaa"
    p1["a"] = "aaa"
    p1.progress = 20
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {"x"=>"aaa", "y"=>"yyy", "a"=>"aaa"}
    assert_equals p1["x"], "aaa"
    assert_equals p1["y"], "yyy"
    assert_equals p1["a"], "aaa"
    assert_equals p1.progress, 20

    #再作成
    p1 = JIJI::ProcessInfo.new( "1", dir )
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {}
    assert_equals p1["x"], nil
    assert_equals p1.progress, 0
    assert_equals p1.data_exist?, true

    #保存されたデータを読み込み
    p1.load
    assert_equals p1.process_id, "1"
    assert_equals p1.props, {"x"=>"aaa", "y"=>"yyy", "a"=>"aaa"}
    assert_equals p1["x"], "aaa"
    assert_equals p1["y"], "yyy"
    assert_equals p1["a"], "aaa"
    assert_equals p1.progress, 0 #進捗は記録されない。


    #別のProcessInfo
    p1 = JIJI::ProcessInfo.new( "2", dir )
    assert_equals p1.process_id, "2"
    assert_equals p1.props, {}
    assert_equals p1["x"], nil
    assert_equals p1.progress, 0
    assert_equals p1.data_exist?, false
  end

  # Processの基本動作のテスト
  def test_backtest_process

    # エージェント設定なし
    pi1 = @registry.process_info( "1" )
    pi1.props = {
      "id"=>"pid1",
      "name"=>"エージェントなし",
      "start_date"=>0,
      "end_date"=>100
    }
    p1 = @registry.backtest_process(pi1)
    agent_mng = p1.agent_manager

    #エージェントを読み込み → 何もロードされない
    p1.load_agents( false )
    assert_equals agent_mng.map, []

    assert_equals agent_mng.operator.trade_enable, false

    # トレードのon/offを設定
    p1.trade_enable = true
    pi1["trade_enable"] = true
    assert_equals agent_mng.operator.trade_enable, true
    p1.trade_enable = false
    pi1["trade_enable"] = false
    assert_equals agent_mng.operator.trade_enable, false
    p1.trade_enable = true
    pi1["trade_enable"] = true
    assert_equals agent_mng.operator.trade_enable, true

    #エージェントを追加
    agents = [
      {"id"=>"aaa",
       "name"=>"テストエージェント1",
       "class"=>"TestAgent@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>30, "y"=>40 }},
      {"id"=>"bbb",
       "name"=>"テストエージェント2",
       "class"=>"TestAgent2@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明2",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>30, "y"=>41 }}
    ]
    pi1["agents"] = agents
    p1.set_agents( agents )
    assert_equals pi1["agents"], agents
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>30, "y"=>40 }
    assert_equals agent_mng.get("bbb").agent.properties, {"x"=>30, "y"=>41 }

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント1"
    assert_equals agent_mng.get("bbb").operator.agent_name, "テストエージェント2"

    out1 = agent_mng.output_manager.get( "1", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント1"
    out2 = agent_mng.output_manager.get( "1", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント2"


    # 変更
    agents = [
      {"id"=>"aaa",
       "name"=>"テストエージェント1",
       "class"=>"TestAgent@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>50, "y"=>40 }},
      {"id"=>"bbb",
       "name"=>"テストエージェント4",
       "class"=>"TestAgent2@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明2aaaaaa",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>60, "y"=>41 }}
    ]
    pi1["agents"] = agents
    p1.set_agents( agents )
    assert_equals pi1["agents"], agents
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>40 }
    assert_equals agent_mng.get("bbb").agent.properties, {"x"=>60, "y"=>41 }

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント1"
    assert_equals agent_mng.get("bbb").operator.agent_name, "テストエージェント4"

    out1 = agent_mng.output_manager.get( "1", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント1"
    out2 = agent_mng.output_manager.get( "1", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント4"

    # 削除
    agents = [
      {"id"=>"aaa",
       "name"=>"テストエージェント11",
       "class"=>"TestAgent@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>50, "y"=>41 }}
    ]
    p1.set_agents( agents )
    pi1["agents"] = agents
    assert_equals pi1["agents"], agents
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb"), nil

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント11"

    out1 = agent_mng.output_manager.get( "1", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント11"
    out2 = agent_mng.output_manager.get( "1", "bbb" ) # outputは削除されない。
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント4"


    # 保存されたデータから再構築
    pi1 = @registry.process_info( "1" )
    pi1.load
    p1 = @registry.backtest_process(pi1)
    agent_mng = p1.agent_manager

    p1.load_agents( false )
    assert_equals p1.agent_manager, agent_mng
    assert_equals pi1["agents"], agents
    assert_equals pi1["trade_enable"], false #バックテストは必ずfalseになる

    assert_equals agent_mng.operator.trade_enable, false #バックテストは必ずfalseになる

    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb"), nil

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント11"

    out1 = agent_mng.output_manager.get( "1", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント11"
    out2 = agent_mng.output_manager.get( "1", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント4"

    p1.stop

    # 作成の段階でエージェントを指定する
    pi2 = @registry.process_info( "2" )
    pi2.props = {
      "id"=>"2",
      "name"=>"エージェントあり",
      "start_date"=>0,
      "end_date"=>100,
      "agents"=>agents
    }
    p2 = @registry.backtest_process(pi2)
    agent_mng = p2.agent_manager

    p2.load_agents( false )
    assert_equals p2.agent_manager, agent_mng
    assert_equals p2.info, pi2
    assert_equals agent_mng.operator.trade_enable, false

    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb"), nil

    out1 = agent_mng.output_manager.get( "2", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント11"

    p2.stop
  end

  # Processの基本動作のテスト
  def test_rmt_process

    p1 = @registry.rmt_process
    agent_mng = p1.agent_manager

    #エージェントを読み込み → 何もロードされない
    p1.load_agents( false )
    assert_equals agent_mng.map, []

    assert_equals agent_mng.operator.trade_enable, false

    # トレードのon/offを設定
    p1.trade_enable = true
    p1.info["trade_enable"] = true
    assert_equals agent_mng.operator.trade_enable, true
    p1.trade_enable = false
    p1.info["trade_enable"] = false
    assert_equals agent_mng.operator.trade_enable, false
    p1.trade_enable = true
    p1.info["trade_enable"] = true
    assert_equals agent_mng.operator.trade_enable, true

    #エージェントを追加
    agents = [
      {"id"=>"aaa",
       "name"=>"テストエージェント1",
       "class"=>"TestAgent@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>30, "y"=>40 }},
      {"id"=>"bbb",
       "name"=>"テストエージェント2",
       "class"=>"TestAgent2@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明2",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>30, "y"=>41 }}
    ]
    p1.set_agents( agents )
    p1.info["agents"] = agents
    assert_equals p1.info["agents"], agents
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>30, "y"=>40 }
    assert_equals agent_mng.get("bbb").agent.properties, {"x"=>30, "y"=>41 }

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント1"
    assert_equals agent_mng.get("bbb").operator.agent_name, "テストエージェント2"

    out1 = agent_mng.output_manager.get( "rmt", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント1"
    out2 = agent_mng.output_manager.get( "rmt", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント2"

    p1.stop
    Test.destry( @registry)
    @registry = JIJI::Registry.new(@dir , nil)
    @registry.plugin_loader.load

    # 保存されたデータから再構築
    p1 = @registry.rmt_process
    agent_mng = p1.agent_manager

    p1.load_agents( false )
    assert_equals p1.agent_manager, agent_mng
    assert_equals p1.info["agents"], agents
    assert_equals p1.info["trade_enable"], true

    assert_equals agent_mng.operator.trade_enable, true

    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>30, "y"=>40 }
    assert_equals agent_mng.get("bbb").agent.properties, {"x"=>30, "y"=>41 }

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント1"
    assert_equals agent_mng.get("bbb").operator.agent_name, "テストエージェント2"

    out1 = agent_mng.output_manager.get( "rmt", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント1"
    out2 = agent_mng.output_manager.get( "rmt", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント2"


    # 削除
    agents = [
      {"id"=>"aaa",
       "name"=>"テストエージェント11",
       "class"=>"TestAgent@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>50, "y"=>41 }}
    ]
    p1.set_agents( agents )
    p1.info["agents"] = agents
    assert_equals p1.info["agents"], agents
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb"), nil

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント11"

    out1 = agent_mng.output_manager.get( "rmt", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント11"
    out2 = agent_mng.output_manager.get( "rmt", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント2"


    p1.info["trade_enable"] = false
    p1.trade_enable = false
    p1.stop
    Test.destry( @registry)
    @registry = JIJI::Registry.new(@dir , nil)
    @registry.plugin_loader.load

    # 保存されたデータから再構築
    p1 = @registry.rmt_process
    agent_mng = p1.agent_manager

    p1.load_agents( false )
    assert_equals p1.agent_manager, agent_mng
    assert_equals p1.info["agents"], agents
    assert_equals p1.info["trade_enable"], false

    assert_equals agent_mng.operator.trade_enable, false
    assert_equals p1.info["agents"], agents
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb"), nil

    assert_equals agent_mng.get("aaa").operator.agent_name, "テストエージェント11"

    out1 = agent_mng.output_manager.get( "rmt", "aaa" )
    assert_equals out1.agent_id, "aaa"
    assert_equals out1.agent_name, "テストエージェント11"
    out2 = agent_mng.output_manager.get( "rmt", "bbb" )
    assert_equals out2.agent_id, "bbb"
    assert_equals out2.agent_name, "テストエージェント2"
  end


  # エージェントの作成でエラーになった場合のテスト
  def test_error

    agents = [
      {"id"=>"aaa",
       "name"=>"テストエージェント1",
       "class"=>"TestAgent@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>50, "y"=>41 }}
    ]

    pi1 = @registry.process_info( "1" )
    pi1.props = {
      "id"=>"pid1",
      "name"=>"エージェントなし",
      "start_date"=>0,
      "end_date"=>100,
      "agents"=>agents
    }
    p1 = @registry.backtest_process(pi1)
    agent_mng = p1.agent_manager
    error_registry = Test::RegistryMock.new # エージェントレジストリをモックに差し替え。
    agent_mng.agent_registry = error_registry

    # 生成時にエラー
    Test::RegistryMock.set_fail_create {|cl,p| true }
    begin
      # エラーを無視しないモードで生成 / 例外が発生する
      p1.load_agents( false )
      fail
    rescue RuntimeError
    end
    assert_equals agent_mng.get("aaa"), nil

    # エラーを無視するモードで生成 / 例外は発生しない
    p1.load_agents( true )
    assert_equals agent_mng.get("aaa"), nil


    # エージェントの追加時にエラー
    agents << {"id"=>"bbb",
       "name"=>"テストエージェント4",
       "class"=>"TestAgent2@foo.rb",
       "class_name" => "TestAgent",
       "file_name" => "foo.rb",
       "description" => "説明2aaaaaa",
       "property_def" => {"id"=>"x", "default"=>85 },
       "properties" => {"x"=>60, "y"=>41 }}
    result = p1.set_agents(agents)
    assert_not_nil result["aaa"][:cause]
    assert_equals result["aaa"][:info], agents[0]
    assert_equals result["aaa"][:operation], :add
    assert_not_nil result["bbb"][:cause]
    assert_equals result["bbb"][:info], agents[1]
    assert_equals result["bbb"][:operation], :add
    assert_equals agent_mng.get("aaa"), nil
    assert_equals agent_mng.get("bbb"), nil

    Test::RegistryMock.set_fail_create {|cl,p| false }

    # エージェントのプロパティ更新時にエラー
    Test::Agent.set_fail_propset {|a| a.cl == "TestAgent@foo.rb" }
    p1.load_agents( false ) # ロードできるようになる。
    assert_equals agent_mng.get("aaa").agent.cl, "TestAgent@foo.rb"
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb").agent.cl, "TestAgent2@foo.rb"
    assert_equals agent_mng.get("bbb").agent.properties, {"x"=>60, "y"=>41 }

    agents[0]["properties"] = {"x"=>80, "y"=>81 }
    agents[1]["properties"] = {"x"=>80, "y"=>81 }
    result = p1.set_agents(agents)
    assert_not_nil result["aaa"][:cause]
    assert_equals result["aaa"][:info], agents[0]
    assert_equals result["aaa"][:operation], :update
    assert_nil result["bbb"]

    #"aaa"のプロパティは更新されていない
    assert_equals agent_mng.get("aaa").agent.cl, "TestAgent@foo.rb"
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb").agent.cl, "TestAgent2@foo.rb"
    assert_equals agent_mng.get("bbb").agent.properties, {"x"=>80, "y"=>81 }
    Test::Agent.set_fail_propset {|a| false }

    # エージェントの削除時にエラー
    class << agent_mng
      def remove( agent_id )
        raise "test" if agent_id == "aaa"
        super
      end
    end

    result = p1.set_agents([])
    assert_not_nil result["aaa"][:cause]
    assert_equals result["aaa"][:info], agents[0]
    assert_equals result["aaa"][:operation], :remove
    assert_nil result["bbb"]

    #エージェント"aaa"は健在
    assert_equals agent_mng.get("aaa").agent.cl, "TestAgent@foo.rb"
    assert_equals agent_mng.get("aaa").agent.properties, {"x"=>50, "y"=>41 }
    assert_equals agent_mng.get("bbb"), nil

    p1.stop
  end

  # エージェントマネージャを再作成する
  def new_agent_mang( process_id, agent_registory=RegistryMock.new )
    agent_mng = JIJI::AgentManager.new( process_id, agent_registory, Logger.new(STDOUT))
    agent_mng.operator = Struct.new(:trade_enable, :agent_name).new(true)
    agent_mng.conf = CONF
    agent_mng.conf.set( [:agent,:safe_level], 0)
    agent_mng.output_manager = JIJI::OutputManager.new( @registry_mock )
    return agent_mng
  end

end