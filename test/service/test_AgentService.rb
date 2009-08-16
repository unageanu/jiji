#!/usr/bin/ruby

$: << "../../lib"
$: << "../../ext_lib"
$: << "../"

require "runit/testcase"
require "runit/cui/testrunner"
require "testutils"

# AgentService のテスト
class AgentServiceTest < Test::AbstractServiceTest
  
  def setup
    super
    @as = Test::JsonRpcRequestor.new("agent")
    
    # 登録
    @as.put_agent_class( "AgentServiceTest_1.rb", BODY_O1 )
    @as.put_agent_class( "AgentServiceTest_2.rb", BODY_O2 )      
  end

  def teardown
    
    # 削除
    begin
      @as.delete_agent_class( "AgentServiceTest_1.rb" )
    ensure
      @as.delete_agent_class( "AgentServiceTest_2.rb" )      
    end
      
    super
  end
  
  # 基本動作のテスト
  def test_hello
    hello_service = Test::JsonRpcRequestor.new("hello")
    assert_equals hello_service.hello, "hello."
  end
  
  # 
  def test_basic
    
    # 一覧
    list = @as.list_agent_class
    agent1   = list.find {|a| a["class_name"] == "TestAgent@AgentServiceTest_1.rb" }
    agent1_2 = list.find {|a| a["class_name"] == "Test::TestAgent2@AgentServiceTest_1.rb" }
    agent2   = list.find {|a| a["class_name"] == "TestAgent@AgentServiceTest_2.rb" }
    
    assert_equals agent1["description"], "テスト\nテスト"
    assert_equals agent1["properties"], [
      {"default"=>10,"type"=>"number","id"=>"period","name"=>"レートの通知を受け取る間隔(分)"},
      {"default"=>1.0,"type"=>"string","id"=>"a","name"=>"aaa"},
      {"default"=>"foo","type"=>"string","id"=>"b","name"=>"bbb"}
    ]
    assert_equals agent1_2["description"], "テスト2"
    assert_equals agent1_2["properties"], []
    assert_equals agent2["description"], "テスト"
    assert_equals agent2["properties"], [
      {"default"=>10,"type"=>"number","id"=>"period","name"=>"レートの通知を受け取る間隔(分)"},
      {"default"=>1.0,"type"=>"string","id"=>"x","name"=>"aaa"},
      {"default"=>"foo","type"=>"string","id"=>"y","name"=>"bbb"}
    ]
    
    # 削除
    @as.delete_agent_class( "AgentServiceTest_1.rb" )
    list = @as.list_agent_class
    agent1   = list.find {|a| a["class_name"] == "TestAgent@AgentServiceTest_1.rb" }
    agent1_2 = list.find {|a| a["class_name"] == "Test::TestAgent2@AgentServiceTest_1.rb" }
    agent2   = list.find {|a| a["class_name"] == "TestAgent@AgentServiceTest_2.rb" }
    assert_nil agent1
    assert_nil agent1_2
    assert_not_nil agent2
    
    # 再登録
    @as.put_agent_class( "AgentServiceTest_1.rb", BODY_O1 )
    
    # RMTのエージェントとして登録
    begin
	    @as.add_agent( "rmt", "AgentServiceTest_その1", 
	      "TestAgent@AgentServiceTest_1.rb", {"a"=>100, "b"=>"value", "period"=>610} )
	    @as.add_agent( "rmt", "AgentServiceTest_その2",
	      "TestAgent@AgentServiceTest_2.rb", {"x"=>200} )
	    
	    agents = @as.list_agent("rmt")
      a1 = agents.find {|a| a["name"] == "AgentServiceTest_その1" }
      a2 = agents.find {|a| a["name"] == "AgentServiceTest_その2" }
      
      assert_equals a1["properties"], [
        {"id"=>"period", "value"=>610, "info"=>{"default"=>10,"type"=>"number","id"=>"period","name"=>"レートの通知を受け取る間隔(分)"}},
        {"id"=>"a",  "value"=>100, "info"=>{"default"=>1.0,"type"=>"string","id"=>"a","name"=>"aaa"}},
        {"id"=>"b",  "value"=>"value", "info"=>{"default"=>"foo","type"=>"string","id"=>"b","name"=>"bbb"}}
      ]
      assert_equals a1["active"], true
      assert_equals a1["description"], "テスト\nテスト"
      
      assert_equals a2["properties"], [
        {"id"=>"period", "value"=>nil, "info"=>{"default"=>10,"type"=>"number","id"=>"period","name"=>"レートの通知を受け取る間隔(分)"}},
        {"id"=>"x",  "value"=>200, "info"=>{"default"=>1.0,"type"=>"string","id"=>"x","name"=>"aaa"}},
        {"id"=>"y",  "value"=>nil, "info"=>{"default"=>"foo","type"=>"string","id"=>"y","name"=>"bbb"}}
      ]
      assert_equals a2["active"], true
      assert_equals a2["description"], "テスト"      
      
      # 状態変更
      assert_equals @as.on?( "rmt", "AgentServiceTest_その1" ), true
      assert_equals @as.on?( "rmt", "AgentServiceTest_その2" ), true
      
      @as.off( "rmt", "AgentServiceTest_その1" )
      assert_equals @as.on?( "rmt", "AgentServiceTest_その1" ), false
      assert_equals @as.on?( "rmt", "AgentServiceTest_その2" ), true
      
      @as.on( "rmt", "AgentServiceTest_その1" )
      assert_equals @as.on?( "rmt", "AgentServiceTest_その1" ), true
      assert_equals @as.on?( "rmt", "AgentServiceTest_その2" ), true
      
    ensure
      begin
	      @as.remove_agent( "rmt", "AgentServiceTest_その1" )
	      agents = @as.list_agent("rmt")
	      a1 = agents.find {|a| a["name"] == "AgentServiceTest_その1" }
	      a2 = agents.find {|a| a["name"] == "AgentServiceTest_その2" }      
	      assert_nil a1
	      assert_not_nil a2
      ensure
	      @as.remove_agent( "rmt", "AgentServiceTest_その2" )
	      agents = @as.list_agent("rmt")
	      a1 = agents.find {|a| a["name"] == "AgentServiceTest_その1" }
	      a2 = agents.find {|a| a["name"] == "AgentServiceTest_その2" }      
	      assert_nil a1
	      assert_nil a2
      end
    end
  end
  
  BODY_O1 =<<-BODY
    class TestAgent < JIJI::PeriodicallyAgent
      include JIJI::Agent
      def initialize
        @a = 1
        @b = "foo"
      end
      def property_infos
        super().concat [
          Property.new( "a", "aaa", 1 ),
          Property.new( "b", "bbb", "foo" )
        ]
      end
      def description
        "テスト\nテスト"
      end
      attr :a, true
      attr :b, true
    end
    module Test
      class TestAgent2
        include JIJI::Agent
        def description
          "テスト2"
        end
      end
    end
  BODY
  BODY_O2 =<<-BODY
    class TestAgent < JIJI::PeriodicallyAgent
      include JIJI::Agent
      def initialize
        @x = 1.0
        @y = "foo"
      end
      def property_infos
        super().concat [
          Property.new( "x", "aaa", 1.0 ),
          Property.new( "y", "bbb", "foo" )
        ]
      end
      def description
        "テスト"
      end
      attr :x, true
      attr :y, true
    end
  BODY
end

