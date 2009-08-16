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
require 'jiji/collector'

# PeriodicallyAgent のテスト
class PeriodicallyAgentTest <  RUNIT::TestCase

  def setup
  end

  def teardown
  end
  
  # 基本動作のテスト
  def test_basic
    
    agent = TestAgent.new( 2 )
    assert_equals agent.log, []
    
    pair_infos = {:USDJPY=>"info"}
    
    agent.next_rates(  JIJI::Rates.new( pair_infos, {
      :USDJPY => R.new( 100.0, 100.05, -200, 222 ),
      :AUDUSD => R.new( 100.0, 100.05, -200, 200 )
    }, Time.local(2008, 8, 1, 10, 0, 0)))
    agent.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => R.new( 100.4, 100.09, -200, 200 ),
      :AUDUSD => R.new(  90.5, 100.00, -330, 330 )
    }, Time.local(2008, 8, 1, 10, 0, 1)))
    agent.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => R.new( 90.6, 110.01, -220, 220 ),
      :AUDUSD => R.new( 90.5, 100.00, -300, 300 )
    }, Time.local(2008, 8, 1, 10, 1, 0)))
    
    # まだ通知されない
    assert_equals agent.log, []
    
    # さらに待ち、データを追加
    agent.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => R.new( 90.7, 110.02, -219, 222 ),
      :AUDUSD => R.new( 90.6, 100.03, -303, 303 )
    }, Time.local(2008, 8, 1, 10, 2, 1)))
    # 通知される
    assert_equals agent.log.length, 1
    r = agent.log[0]
    assert_not_nil r.time
    assert_not_nil r.start_time
    assert_not_nil r.end_time
    assert_equals r.pair_infos, {:USDJPY=>"info"}
    
    assert_equals r[:USDJPY].bid.max,   100.4
    assert_equals r[:USDJPY].bid.min,   90.6
    assert_equals r[:USDJPY].bid.start, 100.0
    assert_equals r[:USDJPY].bid.end,   90.7
    
    assert_equals r[:USDJPY].ask.max,   110.02
    assert_equals r[:USDJPY].ask.min,   100.05
    assert_equals r[:USDJPY].ask.start, 100.05
    assert_equals r[:USDJPY].ask.end,   110.02
    
    assert_equals r[:USDJPY].sell_swap.max,   -200
    assert_equals r[:USDJPY].sell_swap.min,   -220
    assert_equals r[:USDJPY].sell_swap.start, -200
    assert_equals r[:USDJPY].sell_swap.end,   -219
    
    assert_equals r[:USDJPY].buy_swap.max,   222
    assert_equals r[:USDJPY].buy_swap.min,   200
    assert_equals r[:USDJPY].buy_swap.start, 222
    assert_equals r[:USDJPY].buy_swap.end,   222
    
    assert_equals r[:AUDUSD].bid.max,   100.0
    assert_equals r[:AUDUSD].bid.min,   90.5
    assert_equals r[:AUDUSD].bid.start, 100.0
    assert_equals r[:AUDUSD].bid.end,   90.6
    
    assert_equals r[:AUDUSD].ask.max,   100.05
    assert_equals r[:AUDUSD].ask.min,   100.00
    assert_equals r[:AUDUSD].ask.start, 100.05
    assert_equals r[:AUDUSD].ask.end,   100.03
    
    assert_equals r[:AUDUSD].sell_swap.max,   -200
    assert_equals r[:AUDUSD].sell_swap.min,   -330
    assert_equals r[:AUDUSD].sell_swap.start, -200
    assert_equals r[:AUDUSD].sell_swap.end,   -303
    
    assert_equals r[:AUDUSD].buy_swap.max,   330
    assert_equals r[:AUDUSD].buy_swap.min,   200
    assert_equals r[:AUDUSD].buy_swap.start, 200
    assert_equals r[:AUDUSD].buy_swap.end,   303
    
    agent.log.clear
    
    
    # データを追加
    agent.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => R.new( 100.4, 100.09, -200, 200 ),
      :AUDUSD => R.new(  90.5, 100.00, -330, 330 )
    }, Time.local(2008, 8, 1, 10, 3, 0)))
    
    assert_equals agent.log, []
    
    agent.next_rates( JIJI::Rates.new( pair_infos, {
      :USDJPY => R.new( 90.6, 110.01, -220, 220 ),
      :AUDUSD => R.new( 90.5, 100.00, -300, 300 )
    }, Time.local(2008, 8, 1, 10, 4, 2)))
    
    # 通知される
    assert_equals agent.log.length, 1
    r = agent.log[0]
    assert_not_nil r.time
    assert_not_nil r.start_time
    assert_not_nil r.end_time
    assert_equals r.pair_infos, {:USDJPY=>"info"}
    
    assert_equals r[:USDJPY].bid.max,   100.4
    assert_equals r[:USDJPY].bid.min,   90.6
    assert_equals r[:USDJPY].bid.start, 100.4
    assert_equals r[:USDJPY].bid.end,   90.6
    
    assert_equals r[:USDJPY].ask.max,   110.01
    assert_equals r[:USDJPY].ask.min,   100.09
    assert_equals r[:USDJPY].ask.start, 100.09
    assert_equals r[:USDJPY].ask.end,   110.01
    
    assert_equals r[:USDJPY].sell_swap.max,   -200
    assert_equals r[:USDJPY].sell_swap.min,   -220
    assert_equals r[:USDJPY].sell_swap.start, -200
    assert_equals r[:USDJPY].sell_swap.end,   -220
    
    assert_equals r[:USDJPY].buy_swap.max,   220
    assert_equals r[:USDJPY].buy_swap.min,   200
    assert_equals r[:USDJPY].buy_swap.start, 200
    assert_equals r[:USDJPY].buy_swap.end,   220
    
    assert_equals r[:AUDUSD].bid.max,   90.5
    assert_equals r[:AUDUSD].bid.min,   90.5
    assert_equals r[:AUDUSD].bid.start, 90.5
    assert_equals r[:AUDUSD].bid.end,   90.5
    
    assert_equals r[:AUDUSD].ask.max,   100.00
    assert_equals r[:AUDUSD].ask.min,   100.00
    assert_equals r[:AUDUSD].ask.start, 100.00
    assert_equals r[:AUDUSD].ask.end,   100.00
    
    assert_equals r[:AUDUSD].sell_swap.max,   -300
    assert_equals r[:AUDUSD].sell_swap.min,   -330
    assert_equals r[:AUDUSD].sell_swap.start, -330
    assert_equals r[:AUDUSD].sell_swap.end,   -300
    
    assert_equals r[:AUDUSD].buy_swap.max,   330
    assert_equals r[:AUDUSD].buy_swap.min,   300
    assert_equals r[:AUDUSD].buy_swap.start, 330
    assert_equals r[:AUDUSD].buy_swap.end,   300
    
  end
  
end

class TestAgent < JIJI::PeriodicallyAgent
  def initialize( period )
    super
    @log = []
  end
  def next_period_rates( rates )
    @log << rates
  end
  attr :log, true 
end

R = Struct.new( :bid, :ask, :sell_swap, :buy_swap )