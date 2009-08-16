#!/usr/bin/ruby

$: << "../lib"


#clazz = class << Thread; self; end
#clazz.__send__(:alias_method, :start_org, :start )
#def Thread.start(*args, &b)
#  Thread.start_org( caller, *args) {|stack, *arg|
#      Thread.current[:stack] = stack
#      yield( *arg )
#  }
#end
#def Thread.fork(*args, &b)
#  Thread.start_org( caller, *args) {|stack, *arg|
#      Thread.current[:stack] = stack
#      yield( *arg )
#  }
#end
#def Thread.new(*args, &b)
#  Thread.start_org( caller, *args) {|stack, *arg|
#      Thread.current[:stack] = stack
#      yield( *arg )
#  }
#end

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/registry'
require 'logger'
require 'test_utils'

# プロセスマネージャのテスト
class ProcessManagerTest <  RUNIT::TestCase

  include Test::Constants

  def setup
    @dir = File.dirname(__FILE__) + "/ProcessManagerTest"
    FileUtils.rm_rf "#{@dir}/logs"
    FileUtils.rm_rf "#{@dir}/process_logs"
    @registry = JIJI::Registry.new(@dir , nil)
    @registry.plugin_loader.load
    @mng = @registry[:process_manager]
    @omng = @registry[:output_manager]
  end

  def teardown
    Test.destry( @registry, nil )
    FileUtils.rm_rf "#{@dir}/logs"
    FileUtils.rm_rf "#{@dir}/process_logs"
#      Thread.list.each {|t|
#        puts "---#{t}"
#        puts t[:stack]
#      }
  end

  def test_basic
    @mng.start
    agents = [{
      "name" => "aaa",
      "class" => "MovingAverageAgent@moving_average.rb",
      "id"=> "44c0d256-8994-4240-a6c6-8d9546aef8c4",
      "properties" =>  {
          "period" => 10,
          "short" => 25,
          "long" => 75
       }
    }]

    # プロセスを追加
    pid = @mng.create_back_test( "test", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 0.1

    # プロセスを取得
    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid
    assert_equals process["name"], "test"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    # 実行完了を待つ
    sleep 1 while   @mng.get( pid )["state"] == :RUNNING

    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    assert_equals process.process_id, pid
    assert_equals process["name"], "test"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    #別のプロセスを追加
    pid2 = @mng.create_back_test( "test2", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1

    process = @mng.get( pid )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    assert_equals process.process_id, pid
    assert_equals process["name"], "test"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    process = @mng.get( pid2 )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid2
    assert_equals process["name"], "test2"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    # 停止
    @mng.stop

    process = @mng.get( pid )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    assert_equals process.process_id, pid
    assert_equals process["name"], "test"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    process = @mng.get( pid2 )
    assert_equals process["state"], :CANCELED
    assert_not_nil process.progress
    assert_equals process.process_id, pid2
    assert_equals process["name"], "test2"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]


    # マネージャを再作成 / プロセスがローカルのファイルより復元される
    recreate_registry
    @mng = @registry[:process_manager]

    process = @mng.get( pid )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    assert_equals process.process_id, pid
    assert_equals process["name"], "test"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    process = @mng.get( pid2 )
    assert_equals process["state"], :CANCELED
    assert_not_nil process.progress
    assert_equals process.process_id, pid2
    assert_equals process["name"], "test2"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]


    # プロセスを削除
    @mng.delete_back_test( pid )
    assert_process_not_found(pid)

    process = @mng.get( pid2 )
    assert_equals process["state"], :CANCELED
    assert_not_nil process.progress
    assert_equals process.process_id, pid2
    assert_equals process["name"], "test2"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    @mng.delete_back_test( pid2 )
    assert_process_not_found(pid2)

    # マネージャを再作成 / 削除されたデータは消えている筈
    recreate_registry
    @mng = @registry[:process_manager]

    assert_process_not_found(pid)
    assert_process_not_found(pid2)

    # 実行中に削除
    pid3 = @mng.create_back_test( "test3", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 0.1

    process = @mng.get( pid3 )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid3
    assert_equals process["name"], "test3"
    assert_equals process["memo"], "memo"
    assert_equals process["start_date"], Time.gm( 2008, 8, 21 ).to_i
    assert_equals process["end_date"], Time.gm( 2008, 8, 22 ).to_i
    assert_not_nil process["create_date"]

    @mng.delete_back_test( pid3 )
    assert_process_not_found(pid3)

    # マネージャを再作成 / 削除されたデータは消えている筈
    recreate_registry
    @mng = @registry[:process_manager]
    assert_process_not_found(pid3)

  end

  #
  #複数プロセスを同時に起動するテスト。
  #
  def test_multi_process
    @mng.start
    agents = [{
      "name" => "aaa",
      "class" => "MovingAverageAgent@moving_average.rb",
      "id"=> "44c0d256-8994-4240-a6c6-8d9546aef8c4",
      "properties" =>  {
          "period" => 10,
          "short" => 25,
          "long" => 75
       }
    }]

    # プロセスを追加
    pid = @mng.create_back_test( "test", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1

    # プロセスを取得
    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid

    #別のプロセスを追加
    pid2 = @mng.create_back_test( "test2", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1

    #別のプロセスは待機中になる。
    process = @mng.get( pid2 )
    assert_equals process["state"], :WAITING
    assert_not_nil process.progress
    assert_equals process.process_id, pid2

    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid

    # 実行完了を待つ
    sleep 1 while   @mng.get( pid )["state"] == :RUNNING

    process = @mng.get( pid )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    assert_equals process.process_id, pid

    sleep 1

    #別のプロセスが開始される。
    process = @mng.get( pid2 )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid2

    # 別のプロセスを追加して削除
    pid3 = @mng.create_back_test( "test3", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1
    process = @mng.get( pid3 )
    assert_equals process["state"], :WAITING
    assert_not_nil process.progress
    assert_equals process.process_id, pid3

    @mng.delete_back_test( pid3 )
    assert_process_not_found(pid3)

    sleep 1 while   @mng.get( pid2 )["state"] == :RUNNING

    process = @mng.get( pid2 )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    assert_equals process.process_id, pid2

    sleep 10

    ##  待機状態のまま再起動
    # プロセスを追加
    pid4 = @mng.create_back_test( "test4", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 10

    #別のプロセスを追加
    pid5 = @mng.create_back_test( "test5", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]

    process = @mng.get( pid4 )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid4

    process = @mng.get( pid5 )
    assert_equals process["state"], :WAITING
    assert_not_nil process.progress
    assert_equals process.process_id, pid5

    recreate_registry
    @mng = @registry[:process_manager]

    # 実行中のものも待機中のものもキャンセル状態になる。
    process = @mng.get( pid4 )
    assert_equals process["state"], :CANCELED
    assert_not_nil process.progress
    assert_equals process.process_id, pid4

    process = @mng.get( pid5)
    assert_equals process["state"], :CANCELED
    assert_not_nil process.progress
    assert_equals process.process_id, pid5
  end

  #リスタートのテスト。
  def test_restart
    @mng.start
    agents = [{
      "name" => "aaa",
      "class" => "MovingAverageAgent@moving_average.rb",
      "id"=> "44c0d256-8994-4240-a6c6-8d9546aef8c4",
      "properties" =>  {
          "period" => 10,
          "short" => 25,
          "long" => 75
       }
    }]

    # プロセスを追加
    pid = @mng.create_back_test( "test", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1
    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress

    # 実行完了を待つ
    sleep 1 while   @mng.get( pid )["state"] == :RUNNING
    process = @mng.get( pid )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress

    #再起動
    pid = @mng.restart_test( pid )["id"]
    sleep 1
    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress

    #別のプロセスを追加
    pid2 = @mng.create_back_test( "test2", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1

    #別のプロセスは待機中になる。
    process = @mng.get( pid2 )
    assert_equals process["state"], :WAITING
    assert_not_nil process.progress

    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress


    # 実行完了を待つ
    sleep 1 while   @mng.get( pid )["state"] == :RUNNING

    process = @mng.get( pid )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress

    sleep 1

    #別のプロセスが開始される。
    process = @mng.get( pid2 )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress
    assert_equals process.process_id, pid2


    #再起動 / プロセスpid2が実行中なので待機状態になる
    pid = @mng.restart_test( pid )["id"]
    sleep 1
    process = @mng.get( pid )
    assert_equals process["state"], :WAITING
    assert_not_nil process.progress
    assert_equals process.process_id, pid


    #pid2の完了待つ。完了後pid1が起動する。
    sleep 1 while   @mng.get( pid2 )["state"] == :RUNNING

    process = @mng.get( pid2 )
    assert_equals process["state"], :FINISHED
    assert_not_nil process.progress
    sleep 1
    process = @mng.get( pid )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress


    # 別のプロセスを追加してpid1を削除
    pid3 = @mng.create_back_test( "test3", "memo", Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 1
    process = @mng.get( pid3 )
    assert_equals process["state"], :WAITING
    assert_not_nil process.progress

    @mng.delete_back_test( pid )
    assert_process_not_found(pid)

    sleep 1
    process = @mng.get( pid3 )
    assert_equals process["state"], :RUNNING
    assert_not_nil process.progress

    #追加したプロセスも削除
    @mng.delete_back_test( pid3 )
    assert_process_not_found(pid3)

  end

  # プロセスの属性変更のテスト。
  def test_set
    agents =  [{
      "name" => "aaa",
      "class" => "MovingAverageAgent@moving_average.rb",
      "id"=> "44c0d256-8994-4240-a6c6-8d9546aef8c4",
      "properties" =>  {
          "period" => 10,
          "short" => 25,
          "long" => 75
       }
    }]

    @mng.start
    @mng.set("rmt", { "agents"=>agents, "trade_enable"=>false })
    pid1 = @mng.create_back_test( "test", "memo",
      Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 0.1

    ["rmt",pid1].each{|pid|

      #初期状態の確認
      process = @mng.get( pid )
      assert_equals( process["agents"], agents )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, agents[0]["id"]).agent_name, "aaa" )

      #エージェントの追加
      agents2 = agents.map {|i| i.clone }
      agents2 << {
        "name" => "bbb",
        "class" => "MovingAverageAgent@moving_average.rb",
        "id"=> "54c0d256-8994-4240-a6c6-8d9546aef8c4",
        "properties" =>  {
            "period" => 10,
            "short" => 25,
            "long" => 75
        }
      }
      @mng.set( pid, { "agents" => agents2 } )
      process = @mng.get( pid )
      assert_equals( process["agents"], agents2 )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, agents2[0]["id"]).agent_name, "aaa" )
      assert_equals( @omng.get(pid, agents2[1]["id"]).agent_name, "bbb" )


      #エージェントの名前変更
      agents2[0]["name"] = "aaa2"
      @mng.set( pid, { "agents" => agents2 } )
      process = @mng.get( pid )
      assert_equals( process["agents"], agents2 )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, agents2[0]["id"]).agent_name, "aaa2" )
      assert_equals( @omng.get(pid, agents2[1]["id"]).agent_name, "bbb" )


      #エージェントのプロパティ変更
      agents2[0]["properties"] = {
          "period" => 20,
          "short" => 25,
          "long" => 75
      }
      @mng.set( pid, { "agents" => agents2 } )
      process = @mng.get( pid )
      assert_equals( process["agents"], agents2 )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, agents2[0]["id"]).agent_name, "aaa2" )
      assert_equals( @omng.get(pid, agents2[1]["id"]).agent_name, "bbb" )

      #tradeのon/off
      if (  pid == "rmt" ) 
        @mng.set( pid, { "trade_enable" => "true" } )
        process = @mng.get( pid )
        assert_equals( process["agents"], agents2 )
        assert_equals( process["trade_enable"], true )
        assert_equals( @omng.get(pid, agents2[0]["id"]).agent_name, "aaa2" )
        assert_equals( @omng.get(pid, agents2[1]["id"]).agent_name, "bbb" )
        
        @mng.set( pid, { "trade_enable" => "false" } )
        process = @mng.get( pid )
        assert_equals( process["trade_enable"], false )
        
        @mng.set( pid, { "trade_enable" => true } )
        process = @mng.get( pid )
        assert_equals( process["trade_enable"], true )
        
        @mng.set( pid, { "trade_enable" => false } )
        process = @mng.get( pid )
        assert_equals( process["trade_enable"], false )
      else
        # バックテストではtrueにできない
        begin
          @mng.set( pid, { "trade_enable" => "true" } )
          fail
        rescue JIJI::UserError
        end
        process = @mng.get( pid )
        assert_equals( process["agents"], agents2 )
        assert_equals( process["trade_enable"], false )
        assert_equals( @omng.get(pid, agents2[0]["id"]).agent_name, "aaa2" )
        assert_equals( @omng.get(pid, agents2[1]["id"]).agent_name, "bbb" )
      end
  
      #エージェントの削除
      agents3 = agents2[0..1]
      @mng.set( pid, { "agents" => agents3 } )
      process = @mng.get( pid )
      assert_equals( process["agents"], agents3 )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, agents2[0]["id"]).agent_name, "aaa2" )
      assert_equals( @omng.get(pid, agents2[1]["id"]).agent_name, "bbb" )

    }
    @mng.delete_back_test( pid1 )
  end

  # 属性変更の異常系テスト。
  def test_set_error

    agents =  []
    @mng.start
    pid1 = @mng.create_back_test( "test", "memo",
      Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )["id"]
    sleep 0.1

    error_registry = Test::RegistryMock.new
    @mng.rmt.agent_manager.agent_registry = error_registry
    @mng.executor.get( pid1 ).agent_manager.agent_registry = error_registry

    agents_org = [{
      "name" => "aaa",
      "class" => "Test@foo.rb",
      "id"=> "a",
      "properties" =>  {
          "period" => 10,
          "short" => 25,
          "long" => 75
       }
    }]
    @mng.set("rmt", { "agents"=>agents_org, "trade_enable"=>false })
    @mng.set(pid1, { "agents"=>agents_org })

    ["rmt",pid1].each{|pid|
      agents = agents_org.map{|i| i.clone }
      
      #追加でエラー
      Test::RegistryMock.set_fail_create {|cl,p| cl == "Test3@foo.rb" }
      agents2 = agents.map{|i| i.clone }
      agents2 << {
        "name" => "bbb",
        "class" => "Test2@foo.rb",
        "id"=> "b",
        "properties" =>  {
            "period" => 10,
            "short" => 25,
            "long" => 75
        }
      }
      agents2 << {
        "name" => "ccc",
        "class" => "Test3@foo.rb",
        "id"=> "c",
        "properties" =>  {
            "period" => 10,
            "short" => 25,
            "long" => 75
        }
      }
      result = @mng.set( pid, { "agents" => agents2 } )
      assert_not_nil result["c"][:cause]
      assert_equals result["c"][:info], agents2[2]
      assert_equals result["c"][:operation], :add
      assert_nil result["a"]
      assert_nil result["b"]

      agents = agents2[0..1]
      process = @mng.get( pid )
      assert_equals( process["agents"], agents )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, "a").agent_name, "aaa" )
      assert_equals( @omng.get(pid, "b").agent_name, "bbb" )
      begin
        @omng.get(pid, "c")
        fail
      rescue JIJI::UserError
      end

      Test::RegistryMock.set_fail_create {|cl,p| false }

      #更新でエラー
      Test::Agent.set_fail_propset {|a| a.cl == "Test@foo.rb" }
      agents2 = agents.map{|i| i.clone}
      agents2[0]["name"] = "aaa2"
      agents2[0]["properties"] = {
        "period" => 20,
        "short" => 100
      }
      agents2[1]["name"] = "bbb2"
      agents2[1]["properties"] = {
        "period" => 21,
        "short" => 101
      }
      result = @mng.set( pid, { "agents" => agents2 } )
      assert_not_nil result["a"][:cause]
      assert_equals result["a"][:info], agents2[0]
      assert_equals result["a"][:operation], :update
      assert_nil result["b"]

      agents = [agents[0],agents2[1]]
      process = @mng.get( pid )
      assert_equals( process["agents"], agents )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, "a").agent_name, "aaa" )
      assert_equals( @omng.get(pid, "b").agent_name, "bbb2" )
      Test::Agent.set_fail_propset {|a| false }

      #削除でエラー
      target = pid == "rmt" ? @mng.rmt.agent_manager : @mng.executor.get( pid ).agent_manager
      class << target
        def remove( agent_id )
          raise "test" if agent_id == "a"
          super
        end
      end
      result = @mng.set( pid, { "agents" => []} )
      assert_not_nil result["a"][:cause]
      assert_equals result["a"][:info], agents[0]
      assert_equals result["a"][:operation], :remove
      assert_nil result["b"]

      process = @mng.get( pid )
      assert_equals( process["agents"], [agents[0]] )
      assert_equals( process["trade_enable"], false )
      assert_equals( @omng.get(pid, "a").agent_name, "aaa" )
      assert_equals( @omng.get(pid, "b").agent_name, "bbb2" )

    }
    @mng.delete_back_test( pid1 )
  end

  # 異常系テスト。
  def test_error
    # RMT起動時にエージェント作成でエラー / ログ出力のみ行なわれ、処理は継続
    @mng.start
    agents = [{
      "name" => "aaa",
      "class" => "MovingAverageAgent@moving_average.rb",
      "id"=> "a",
      "properties" =>  {}
    }]
    @mng.set( "rmt", {"agents"=>agents});
    process = @mng.get( "rmt" )
    assert_equals( process["agents"], agents )

    recreate_registry
    @registry[:agent_registry].unload( "agents/moving_average.rb" )
    @mng = @registry[:process_manager]
    @mng.start # エラーが発生しない
    process = @mng.get( "rmt" )
    assert_equals( process["agents"], agents ) # 設定はそのまま保持されている


    # バックテスト作成時にエージェント作成でエラー / 例外が返される。
    begin
      @mng.create_back_test( "test", "memo",
        Time.gm( 2008, 8, 21 ).to_i, Time.gm( 2008, 8, 22 ).to_i, agents )
      fail
    rescue JIJI::UserError
    end
  end

  def recreate_registry
    Test.destry( @registry )
    FileUtils.rm_rf "#{@dir}/logs"
    return @registry = JIJI::Registry.new(@dir , nil)
  end

  # プロセスが存在しないことを確認する。
  def assert_process_not_found( pid )
    begin
      @mng.get( pid )
      fail
    rescue JIJI::UserError
      assert_equals JIJI::ERROR_NOT_FOUND, $!.code
    end
  end

end