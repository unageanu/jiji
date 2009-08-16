#!/usr/bin/ruby

$: << "../lib"

require 'runit/testcase'
require 'runit/cui/testrunner'
require 'jiji/registry'
require 'fileutils'

class OutputManagerTest <  RUNIT::TestCase

  def setup
    @dir = File.dirname(__FILE__) + "/OutputregistryTest"
    @registry = JIJI::Registry.new(@dir , nil)
    @registry.plugin_loader.load
    @mng = @registry.output_manager
  end

  def teardown
    Test.destry( @registry, @dir )
    FileUtils.rm_rf "#{@dir}/agents"
    FileUtils.rm_rf "#{@dir}/shared_lib"
  end

  def test_basic

    #最初はデータがない
    assert_equals read( "pid1" ), []

    #outputを作成
    out1_1 = @mng.create( "pid1", "agent1" )
    out1_2 = @mng.create( "pid1", "agent2" )
    out2_1 = @mng.create( "pid2", "agent1" )

    out1_1.agent_name = "agent1_name"
    out1_2.agent_name = "agent2_name"
    out2_1.agent_name = "agent1_name"

    assert_equals out1_1.agent_id, "agent1"
    assert_equals out1_2.agent_id, "agent2"
    assert_equals out2_1.agent_id, "agent1"

    #すでに作成済みのものを作成 → 同じインスタンスが返される
    out1_1_2 = @mng.create( "pid1", "agent1" )
    assert_equals out1_1.object_id, out1_1_2.object_id

    #作成したoutputを取得
    out1_1 = @mng.get( "pid1", "agent1" )
    out1_2 = @mng.get( "pid1", "agent2" )
    out2_1 = @mng.get( "pid2", "agent1" )

    assert_equals out1_1.agent_id, "agent1"
    assert_equals out1_2.agent_id, "agent2"
    assert_equals out2_1.agent_id, "agent1"

    #未作成のものを取得→エラー
    assert_error( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @mng.get( "not found", "agent2" )
    }
    assert_error( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @mng.get( "pid1", "not found" )
    }

    #列挙
    assert_equals read( "pid1" ), [
      out1_1, out1_2
    ]
    assert_equals read( "pid2" ), [
      out2_1
    ]
    assert_equals @mng.get_process_map( "pid1" ), {
      "agent1"=>out1_1,
      "agent2"=>out1_2
    }
    assert_equals @mng.get_process_map( "pid2" ), {
      "agent1"=>out2_1
    }

    #存在しないものを列挙 → 空と同じ扱いになる
    assert_equals read( "not found" ), []
    assert_equals @mng.get_process_map( "not found" ), {}


    #削除
    @mng.delete( "pid1", "agent2" )
    assert_equals read( "pid1" ), [
      out1_1
    ]
    assert_equals @mng.get_process_map( "pid1" ), {
      "agent1"=>out1_1
    }
    assert_error( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @mng.get( "pid1", "agent2" )
    }

    #再作成
    Test.destry( @registry )
    @registry = JIJI::Registry.new(@dir , nil)
    @registry.plugin_loader.load
    @mng = @registry.output_manager

    #取得、作成、削除を一通り試す
    out1_1 = @mng.get( "pid1", "agent1" )
    out2_1 = @mng.get( "pid2", "agent1" )

    assert_equals out1_1.agent_id, "agent1"
    assert_equals out2_1.agent_id, "agent1"

    assert_equals read( "pid1" ), [
      out1_1
    ]
    assert_equals read( "pid2" ), [
      out2_1
    ]
    assert_equals @mng.get_process_map( "pid1" ), {
      "agent1"=>out1_1
    }
    assert_equals @mng.get_process_map( "pid2" ), {
      "agent1"=>out2_1
    }

    out1_3 = @mng.create( "pid1", "agent3" )
    out1_3.agent_name = "agent3_name"
    assert_equals out1_3.agent_id, "agent3"
    assert_equals read( "pid1" ), [
      out1_1, out1_3
    ]
    assert_equals @mng.get_process_map( "pid1" ), {
      "agent1"=>out1_1, "agent3"=>out1_3
    }

    @mng.delete( "pid1", "agent1" )
    assert_equals read( "pid1" ), [
      out1_3
    ]
    assert_equals @mng.get_process_map( "pid1" ), {
      "agent3"=>out1_3
    }
    assert_error( JIJI::UserError, JIJI::ERROR_NOT_FOUND ) {
      @mng.get( "pid1", "agent1" )
    }

  end

  #例外が発生することを評価する。
  #codeも評価したいので独自で作成。
  def assert_error( error, code )
    begin
      yield
      fail
    rescue error
      assert_equals $!.code, code
    end
  end

  #指定されたプロセスのoutput一覧を得る
  def read( process_id )
    list = []
    @mng.each( process_id ) {|row| list << row }
    return list.sort_by {|i| i.agent_id }
  end
end